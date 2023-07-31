import { toMap }                                                                 from "./utils";
import { _SERVICE as MasterService, Account }                                    from "../declarations/godwin_master/godwin_master.did";
import { _SERVICE as SubService, Category, CategoryInfo, SchedulerParameters }   from "../declarations/godwin_sub/godwin_sub.did";
import { _SERVICE as TokenService }                                              from "../declarations/godwin_token/godwin_token.did";
import { _SERVICE as AirdopService }                                             from "../declarations/godwin_airdrop/godwin_airdrop.did";
import { canisterId as masterId, createActor as createMaster, godwin_master }    from "../declarations/godwin_master";
import { godwin_token }                                                          from "../declarations/godwin_token";
import { canisterId as airdropId, createActor as createAirdrop, godwin_airdrop } from "../declarations/godwin_airdrop";
import { createActor as createSub }                                              from "../declarations/godwin_sub";

import { AuthClient }                                                            from "@dfinity/auth-client";
import { ActorSubclass }                                                         from "@dfinity/agent";
import { Principal }                                                             from "@dfinity/principal";
import { fromNullable }                                                          from "@dfinity/utils";

import { useState, useEffect }                                                   from "react";
import { useNavigate }                                                           from "react-router-dom";

import React                                                                     from 'react'

export type Sub = {
  actor: ActorSubclass<SubService>;
  name: string;
  categories: Map<Category, CategoryInfo>;
  scheduler_parameters: SchedulerParameters;
};

export const ActorContext = React.createContext<{
  authClient?: AuthClient;
  setAuthClient?: React.Dispatch<AuthClient>;
  isAuthenticated?: boolean | null;
  setIsAuthenticated?: React.Dispatch<React.SetStateAction<boolean | null>>;
  subsFetched?: boolean | null;
  setSubsFetched?: React.Dispatch<React.SetStateAction<boolean | null>>;
  addSub: (principal: Principal, id: string) => Promise<void>;
  login: () => void;
  logout: () => void;
  token: ActorSubclass<TokenService>;
  airdrop: ActorSubclass<AirdopService>;
  master: ActorSubclass<MasterService>;
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
  airdrop: godwin_airdrop,
  master: godwin_master,
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
  const [token                              ] = useState<ActorSubclass<TokenService>> (godwin_token  );
  const [master,          setMaster         ] = useState<ActorSubclass<MasterService>>(godwin_master );
  const [airdrop,         setAirdrop        ] = useState<ActorSubclass<AirdopService>>(godwin_airdrop);
  const [subs,            setSubs           ] = useState<Map<string, Sub>>            (new Map()     );
  const [subsFetched,     setSubsFetched    ] = useState<boolean | null>              (true          );
  const [userAccount,     setUserAccount    ] = useState<Account | null>              (null          );
  const [loggedUserName,  setLoggedUserName ] = useState<string | undefined>          (undefined     );
  const [balance,         setBalance        ] = useState<bigint | null>               (null          );

  const login = () => {
    authClient?.login({
      identityProvider:
      import.meta.env.DFX_NETWORK === "ic"
          ? "https://identity.ic0.app/#authorize"
          : `http://localhost:${import.meta.env.DFX_REPLICA_PORT}?canisterId=${import.meta.env.CANISTER_ID_INTERNET_IDENTITY}#authorize`,
      // 7 days in nanoseconds
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      onSuccess: () => {
        setIsAuthenticated(true);
      },
    });
  };

  const initAirdrop = () => {
    if (isAuthenticated) {
      const actor = createAirdrop(airdropId as string, {
        agentOptions: {
          identity: authClient?.getIdentity(),
        },
      });
      setAirdrop(actor);
    } else {
      setAirdrop(godwin_airdrop);
    }
  }

  const initMaster = () => {
    if (isAuthenticated) {
      const actor = createMaster(masterId as string, {
        agentOptions: {
          identity: authClient?.getIdentity(),
        },
      });
      setMaster(actor);
    } else {
      setMaster(godwin_master);
    }
  }

  const logout = () => {
    authClient?.logout().then(() => {
      // Somehow if only the isAuthenticated flag is set to false, the next login will fail
      // Refreshing the auth client fixes this behavior
      refreshAuthClient();
      navigate("/");
    });
  }

  const addSub = async (principal: Principal, id: string) : Promise<void> => {
    let actor = createSub(principal, {
      agentOptions: {
        identity: authClient?.getIdentity(),
      },
    });
    let name = await actor.getName();
    let categories = toMap(await actor.getCategories());
    let scheduler_parameters = await actor.getSchedulerParameters();
    setSubs((subs) => new Map(subs).set(id, {actor, name, categories, scheduler_parameters}));
  }

  const fetchSubs = async() => {
    let newSubs = new Map<string, Sub>();
    let listSubs = await master.listSubGodwins();

    await Promise.all(listSubs.map(async ([principal, id]) => {
      let actor = createSub(principal, {
        agentOptions: {
          identity: authClient?.getIdentity(),
        },
      });
      let name = await actor.getName();
      let categories = toMap(await actor.getCategories());
      let scheduler_parameters = await actor.getSchedulerParameters();
      newSubs.set(id, {actor, name, categories, scheduler_parameters});
    }));

    setSubs(newSubs);
    setSubsFetched(true);
  }

  const refreshUserAccount = () => {
    if (isAuthenticated) {
      let principal = authClient?.getIdentity().getPrincipal();
      if (principal !== undefined && !principal.isAnonymous()){
        master.getUserAccount(principal).then((account) => {
          setUserAccount(account);
        });
        return;
      }
    }
    setUserAccount(null);
  }

  const refreshBalance = () => {
    if (userAccount !== null) {
      token.icrc1_balance_of(userAccount).then((balance) => {;
        setBalance(balance);
      });
    } else {
      setBalance(null);
    }
  }

  const refreshLoggedUserName = () => {
    let principal = authClient?.getIdentity().getPrincipal();
    if (principal !== undefined){
      master.getUserName(principal).then((name) => {
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
        disableDefaultIdleCallback: true,
        disableIdle: true
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
    refreshAuthClient();
  }, []);

  useEffect(() => {
    if (!subsFetched) {
      fetchSubs();
    }
  }, [subsFetched]);

  useEffect(() => {
    initMaster();
    initAirdrop();
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
    subsFetched,
    setSubsFetched,
    addSub,
    login,
    logout,
    token,
    airdrop,
    master,
    subs,
    userAccount,
    balance,
    refreshBalance,
    loggedUserName,
    refreshLoggedUserName,
    getPrincipal
  };
}