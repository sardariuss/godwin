import { toMap }                                                                 from "./utils";
import { _SERVICE as MasterService, Account }                                    from "../declarations/godwin_master/godwin_master.did";
import { _SERVICE as SubService, CategoryInfo, 
  SchedulerParameters, PriceRegister, SubInfo as IdlSubInfo, 
  SelectionParameters, Momentum  }                                               from "../declarations/godwin_sub/godwin_sub.did";
import { _SERVICE as TokenService }                                              from "../declarations/godwin_token/godwin_token.did";
import { _SERVICE as AirdopService }                                             from "../declarations/godwin_airdrop/godwin_airdrop.did";
import { canisterId as masterId, createActor as createMaster, godwin_master }    from "../declarations/godwin_master";
import { canisterId as tokenId, createActor as createToken, godwin_token }       from "../declarations/godwin_token";
import { canisterId as airdropId, createActor as createAirdrop, godwin_airdrop } from "../declarations/godwin_airdrop";
import { createActor as createSub }                                              from "../declarations/godwin_sub";

import { AuthClient }                                                            from "@dfinity/auth-client";
import { ActorSubclass, Identity }                                               from "@dfinity/agent";
import { Principal }                                                             from "@dfinity/principal";
import { fromNullable }                                                          from "@dfinity/utils";

import { createContext, useContext, useEffect, useState }                        from "react";
import { useNavigate }                                                           from "react-router-dom";

type SubInfo = {
  name: string;
  character_limit: bigint;
  categories: Map<string, CategoryInfo>;
  selection_parameters: SelectionParameters;
  scheduler_parameters: SchedulerParameters;
  prices: PriceRegister;
  momentum: Momentum;
}

const fromIdlSubInfo = (info: IdlSubInfo) : SubInfo => {
  return {
    name: info.name,
    character_limit: info.character_limit,
    categories: toMap(info.categories),
    selection_parameters: info.selection_parameters,
    scheduler_parameters: info.scheduler_parameters,
    prices: info.prices,
    momentum: info.momentum
  };
}

export type Sub = {
  actor: ActorSubclass<SubService>;
  info: SubInfo;
};

export const ActorContext = createContext<{
  isAuthenticated: boolean,
  principal: Principal,
  token: ActorSubclass<TokenService>;
  airdrop: ActorSubclass<AirdopService>;
  master: ActorSubclass<MasterService>;
  subs: Map<string, Sub>;
  loggedUserName?: string | undefined;
  userAccount?: Account | null;
  balance?: bigint | null;
  login: () => void;
  logout: () => void;
  refreshSubs?: () => Promise<void>;
  addSub: (principal: Principal, id: string) => Promise<void>;
  refreshBalance: () => void;
  refreshLoggedUserName: () => void;
}>({
  isAuthenticated: false,
  principal: Principal.anonymous(),
  token: godwin_token,
  airdrop: godwin_airdrop,
  master: godwin_master,
  subs: new Map(),
  login: () => {},
  logout: () => {},
  addSub: () => Promise.resolve(),
  refreshBalance: () => {},
  refreshLoggedUserName: () => {},
});

const defaultOptions = {
  /**
   *  @type {import("@dfinity/auth-client").AuthClientCreateOptions}
   */
  createOptions: {
    idleOptions: {
      // Set to true if you do not want idle functionality
      disableIdle: true,
    },
  },
  /**
   * @type {import("@dfinity/auth-client").AuthClientLoginOptions}
   */
  loginOptions: {
    identityProvider:
      import.meta.env.DFX_NETWORK === "ic"
        ? "https://identity.ic0.app/#authorize"
        : `http://localhost:${import.meta.env.DFX_REPLICA_PORT}?canisterId=${import.meta.env.CANISTER_ID_INTERNET_IDENTITY}#authorize`,
  },
};

/**
 *
 * @param options - Options for the AuthClient
 * @param {AuthClientCreateOptions} options.createOptions - Options for the AuthClient.create() method
 * @param {AuthClientLoginOptions} options.loginOptions - Options for the AuthClient.login() method
 * @returns
 */
export const useAuthClient = (options = defaultOptions) => {

  const navigate = useNavigate();

  // Authentication
  const [authClient,      setAuthClient     ] = useState<AuthClient | null>           (null          );
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>                     (false         );
  const [identity,        setIdentity       ] = useState<Identity | null>             (null          );
  const [principal,       setPrincipal      ] = useState<Principal>                   (Principal.anonymous());
  // Actors
  const [token,           setToken          ] = useState<ActorSubclass<TokenService>> (godwin_token  );
  const [master,          setMaster         ] = useState<ActorSubclass<MasterService>>(godwin_master );
  const [airdrop,         setAirdrop        ] = useState<ActorSubclass<AirdopService>>(godwin_airdrop);
  const [subs,            setSubs           ] = useState<Map<string, Sub>>            (new Map()     );
  // Misc
  const [loggedUserName,  setLoggedUserName ] = useState<string | undefined>          (undefined     );
  const [userAccount,     setUserAccount    ] = useState<Account | null>              (null          );
  const [balance,         setBalance        ] = useState<bigint | null>               (null          );

  useEffect(() => {
    // Initialize AuthClient
    AuthClient.create(options.createOptions).then(async (client) => {
      updateClient(client);
    });
  }, []);

  const login = () => {
    authClient?.login({
      ...options.loginOptions,
      onSuccess: () => {
        updateClient(authClient);
      },
    });
  };

  async function updateClient(client: AuthClient) {
    // Update all authentication related state
    const isAuthenticated = await client.isAuthenticated();
    setIsAuthenticated(isAuthenticated);
    const identity = client.getIdentity();
    setIdentity(identity);
    const principal = identity.getPrincipal();
    setPrincipal(principal);
    setAuthClient(client);

    // Update all actors
    setToken  (createToken  (tokenId   as string, {agentOptions: { identity }}));
    setMaster (createMaster (masterId  as string, {agentOptions: { identity }}));
    setAirdrop(createAirdrop(airdropId as string, {agentOptions: { identity }}));
    await fetchSubs();

    // Update misc
    refreshLoggedUserName();
    refreshUserAccount();
    refreshBalance();
  }

  async function logout() {
    if (authClient !== null){
      await authClient.logout();
      await updateClient(authClient);
    }
    navigate("/");
  }

  const addSub = async (principal: Principal, id: string) : Promise<void> => {
    if (subs.has(id)) {
      return;
    }
    let actor = createSub(principal, {agentOptions: { identity } });
    let info = await actor.getSubInfo();
    setSubs((subs) => new Map(subs).set(id, {actor, info: fromIdlSubInfo(info)}));
  }

  const refreshSubs = async () => {
    let listSubs = await master.listSubGodwins();
    await Promise.all(listSubs.map(async ([principal, id]) => {
      if (!subs.has(id)) {
        await addSub(principal, id);
      }
    }));
  }

  const fetchSubs = async() => {
    let newSubs = new Map<string, Sub>();
    let listSubs = await master.listSubGodwins();

    await Promise.all(listSubs.map(async ([principal, id]) => {
      let actor = createSub(principal, { agentOptions: { identity } });
      let info = await actor.getSubInfo();
      newSubs.set(id, {actor, info: fromIdlSubInfo(info)});
    }));

    setSubs(newSubs);
  }

  const refreshUserAccount = () => {
    if (principal !== undefined && !principal.isAnonymous()){
      master.getUserAccount(principal).then((account) => { setUserAccount(account) });
    } else {
      setUserAccount(null);
    }
  }

  const refreshBalance = () => {
    if (userAccount !== null) {
      token.icrc1_balance_of(userAccount).then((balance) => { setBalance(balance) });
    } else {
      setBalance(null);
    }
  }

  const refreshLoggedUserName = () => {
    if (principal !== undefined && !principal.isAnonymous()){
      master.getUserName(principal).then((name) => { setLoggedUserName(fromNullable(name)) });
    } else {
      setLoggedUserName(undefined);
    }
  }

  // Refreshing balance when userAccount changes
  useEffect(() => {
    refreshBalance();
  }, [userAccount]);

  return {
    isAuthenticated,
    principal,
    token,
    master,
    airdrop,
    subs,
    loggedUserName,
    userAccount,
    balance,
    login,
    logout,
    refreshSubs,
    addSub,
    refreshBalance,
    refreshLoggedUserName
  };
};

/**
 * @type {React.FC}
 */
export const AuthProvider = ({ children }) => {
  const auth = useAuthClient();

  return <ActorContext.Provider value={auth}>{children}</ActorContext.Provider>;
};

export const useAuth = () => useContext(ActorContext);
