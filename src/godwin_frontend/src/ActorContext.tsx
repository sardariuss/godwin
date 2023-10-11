import { createActor }                                                           from "./AgentUtils";
import { toMap }                                                                 from "./utils";
import { _SERVICE as MasterService, Account }                                    from "../declarations/godwin_master/godwin_master.did";
import { _SERVICE as SubService, CategoryInfo, 
  SchedulerParameters, SubInfo as IdlSubInfo, 
  SelectionParameters, Momentum, PriceParameters }                               from "../declarations/godwin_sub/godwin_sub.did";
import { _SERVICE as CKBTCService }                                              from "../declarations/ck_btc/ck_btc.did";
import { _SERVICE as TokenService }                                              from "../declarations/godwin_token/godwin_token.did";
import { canisterId as masterId, idlFactory as masterFactory, godwin_master   }  from "../declarations/godwin_master";
import { ck_btc }                                                                from "../declarations/ck_btc";
import { godwin_token }                                                          from "../declarations/godwin_token";
import { idlFactory as subFactory }                                              from "../declarations/godwin_sub";

import { AuthClient }                                                            from "@dfinity/auth-client";
import { ActorSubclass }                                                         from "@dfinity/agent";
import { Principal }                                                             from "@dfinity/principal";
import { fromNullable }                                                          from "@dfinity/utils";

import { useState, useEffect }                                                   from "react";
import { useNavigate }                                                           from "react-router-dom";

import React                                                                     from 'react'

type SubInfo = {
  name: string;
  character_limit: bigint;
  categories: Map<string, CategoryInfo>;
  selection_parameters: SelectionParameters;
  scheduler_parameters: SchedulerParameters;
  momentum: Momentum;
}

const fromIdlSubInfo = (info: IdlSubInfo) : SubInfo => {
  return {
    name: info.name,
    character_limit: info.character_limit,
    categories: toMap(info.categories),
    selection_parameters: info.selection_parameters,
    scheduler_parameters: info.scheduler_parameters,
    momentum: info.momentum
  };
}

export type Sub = {
  actor: ActorSubclass<SubService>;
  info: SubInfo;
  id: string;
};

export const ActorContext = React.createContext<{
  authClient?: AuthClient;
  setAuthClient?: React.Dispatch<AuthClient>;
  isAuthenticated?: boolean | null;
  setIsAuthenticated?: React.Dispatch<React.SetStateAction<boolean | null>>;
  refreshSubs?: () => Promise<void>;
  addSub: (principal: Principal, id: string) => Promise<void>;
  login: () => void;
  logout: () => void;
  ck_btc: ActorSubclass<CKBTCService> | undefined;
  token: ActorSubclass<TokenService> | undefined;
  master: ActorSubclass<MasterService> | undefined;
  priceParameters: PriceParameters | undefined;
  subs: Map<string, Sub>;
  userAccount?: Account | null;
  balance: bigint | null;
  refreshBalance: () => void;
  loggedUserName?: string | undefined;
  refreshLoggedUserName: () => void;
  getPrincipal: () => Principal;
}>({
  addSub: () => Promise.resolve(),
  login: () => {},
  logout: () => {},
  token: godwin_token,
  ck_btc: ck_btc,
  master: godwin_master,
  priceParameters: undefined,
  subs: new Map(),
  balance: null,
  refreshBalance: () => {},
  loggedUserName: undefined,
  refreshLoggedUserName: () => {},
  getPrincipal: () => Principal.anonymous()
});

export function useAuthClient() {
  const navigate = useNavigate();

  const [authClient,      setAuthClient     ] = useState<AuthClient | undefined>      (undefined     );
  const [isAuthenticated, setIsAuthenticated] = useState<null | boolean>              (null          );
  const [master,          setMaster         ] = useState<ActorSubclass<MasterService> | undefined>(godwin_master );
  const [priceParameters, setPriceParameters] = useState<PriceParameters | undefined> (undefined     );
  const [subs,            setSubs           ] = useState<Map<string, Sub>>            (new Map()     );
  const [userAccount,     setUserAccount    ] = useState<Account | null>              (null          );
  const [loggedUserName,  setLoggedUserName ] = useState<string | undefined>          (undefined     );
  const [balance,         setBalance        ] = useState<bigint | null>               (null          );

  const login = () => {
    authClient?.login({
      identityProvider:
        import.meta.env.DFX_NETWORK === "ic" ? 
          `https://identity.ic0.app/#authorize` : 
          `http://localhost:${import.meta.env.DFX_REPLICA_PORT}?canisterId=${import.meta.env.CANISTER_ID_INTERNET_IDENTITY}#authorize`,
      // 7 days in nanoseconds
      maxTimeToLive: BigInt(8) * BigInt(3_600_000_000_000),
      onSuccess: () => { setIsAuthenticated(true); },
    });
  };

  const logout = () => {
    authClient?.logout().then(() => {
      // Somehow if only the isAuthenticated flag is set to false, the next login will fail
      // Refreshing the auth client fixes this behavior
      refreshAuthClient();
      navigate("/");
    });
  }

  const refreshMaster = async () => {
    setMaster(
      await createActor({
        canisterId: masterId,
        idlFactory: masterFactory,
        identity: authClient?.getIdentity(), 
      })
    );
  }

  const refreshPriceParameters = async () => {
    let params = await godwin_master?.getPriceParameters();
    setPriceParameters(params);
  }

  const createSub = async (principal: Principal, id: string) : Promise<Sub> => {
    let actor : ActorSubclass<SubService> = await createActor({
      canisterId: principal.toString(),
      idlFactory: subFactory,
      identity: authClient?.getIdentity(), 
    });
    let info = await actor.getSubInfo();
    return {id, actor, info: fromIdlSubInfo(info)};
  }

  const addSub = async (principal: Principal, id: string) => {
    if (!subs.has(id)) {
      let sub = await createSub(principal, id);
      setSubs((subs) => new Map(subs).set(id, sub));
    }
  }

  const refreshSubs = async () => {
    let listSubs = await master?.listSubGodwins() ?? [];
    await Promise.all(listSubs.map(async ([principal, id]) => {
      addSub(principal, id);
    }));
  }

  const fetchSubs = async() => {
    let newSubs = new Map<string, Sub>();
    let listSubs = await master?.listSubGodwins() ?? [];

    await Promise.all(listSubs.map(async ([principal, id]) => {
      let sub = await createSub(principal, id);
      newSubs.set(id, sub);
    }));

    setSubs(newSubs);
  }

  const refreshUserAccount = () => {
    if (isAuthenticated) {
      let principal = authClient?.getIdentity().getPrincipal();
      if (principal !== undefined && !principal.isAnonymous()){
        master?.getUserAccount(principal).then((account) => {
          setUserAccount(account);
        });
        return;
      }
    }
    setUserAccount(null);
  }

  const refreshBalance = () => {
    if (userAccount !== null) {
      ck_btc?.icrc1_balance_of(userAccount).then((balance) => {;
        setBalance(balance);
      });
    } else {
      setBalance(null);
    }
  }

  const refreshLoggedUserName = () => {
    let principal = authClient?.getIdentity().getPrincipal();
    if (principal !== undefined){
      master?.getUserName(principal).then((name) => {
        setLoggedUserName(fromNullable(name));
      }
    )} else {
      setLoggedUserName(undefined);
    }
  }

  const getPrincipal = () => {
    return authClient?.getIdentity().getPrincipal() ?? Principal.anonymous();
  };

  const refreshAuthClient = () => {
    AuthClient.create({
      idleOptions: {
        captureScroll: true,
        idleTimeout: 900000, // 15 minutes
      }
    }).then(async (client) => {
      const is_authenticated = await client.isAuthenticated();
      setAuthClient(client);
      setIsAuthenticated(is_authenticated);
    })
    .catch((error) => {
      console.error(error);
      setAuthClient(undefined);
      setIsAuthenticated(false);
    });
  };

  useEffect(() => {
    refreshPriceParameters();
    refreshAuthClient();
  }, []);

  useEffect(() => {
    refreshMaster();
    refreshUserAccount();
    refreshLoggedUserName();
    fetchSubs();
  }, [isAuthenticated]);

  // Refreshing balance when userAccount changes
  useEffect(() => {
    refreshBalance();
  }, [userAccount]);

  return {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    refreshSubs,
    addSub,
    login,
    logout,
    ck_btc,
    token: godwin_token,
    master,
    priceParameters,
    subs,
    userAccount,
    balance,
    refreshBalance,
    loggedUserName,
    refreshLoggedUserName,
    getPrincipal
  };
}