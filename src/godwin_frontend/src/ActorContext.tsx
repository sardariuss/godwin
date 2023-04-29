import { AuthClient, IdbStorage } from "@dfinity/auth-client";
import { DelegationChain, isDelegationValid } from "@dfinity/identity";

import { _SERVICE as MasterService } from "../declarations/godwin_master/godwin_master.did";
import { _SERVICE as SubService, CategoryArray__1 } from "../declarations/godwin_backend/godwin_backend.did";
import { _SERVICE as TokenService } from "../declarations/godwin_token/godwin_token.did";
import { canisterId, createActor as createMaster, godwin_master } from "../declarations/godwin_master";
import { godwin_token } from "../declarations/godwin_token";
import { createActor as createSub } from "../declarations/godwin_backend";
import { ActorSubclass } from "@dfinity/agent";

import { useState, useEffect } from "react";

import { useNavigate } from "react-router-dom";

import React from 'react'

export type Sub = {
  actor: ActorSubclass<SubService>;
  name: string;
  categories: CategoryArray__1;
};

export const ActorContext = React.createContext<{
  authClient?: AuthClient;
  setAuthClient?: React.Dispatch<AuthClient>;
  isAuthenticated?: boolean | null;
  setIsAuthenticated?: React.Dispatch<React.SetStateAction<boolean | null>>;
  subsFetched?: boolean | null;
  setSubsFetched?: React.Dispatch<React.SetStateAction<boolean | null>>;
  login: () => void;
  logout: () => void;
  token: ActorSubclass<TokenService>;
  master: ActorSubclass<MasterService>;
  subs: Map<string, Sub>;
  hasLoggedIn: boolean;
}>({
  login: () => {},
  logout: () => {},
  token: godwin_token,
  master: godwin_master,
  subs: new Map(),
  hasLoggedIn: false
});

export function useAuthClient() {
  const navigate = useNavigate();

  const [authClient, setAuthClient] = useState<AuthClient>();
  const [isAuthenticated, setIsAuthenticated] = useState<null | boolean>(null);
  const [hasLoggedIn, setHasLoggedIn] = useState(false);
  const [token] = useState<ActorSubclass<TokenService>>(godwin_token);
  const [master, setMaster] = useState<ActorSubclass<MasterService>>(godwin_master);
  const [subs, setSubs] = useState<Map<string, Sub>>(new Map());
  const [subsFetched, setSubsFetched] = useState<boolean | null>(true);

  const login = () => {
    authClient?.login({
      identityProvider:
        process.env.DFX_NETWORK === "ic"
          ? "https://identity.ic0.app/#authorize"
          : `http://localhost:${process.env.REPLICA_PORT}?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID}#authorize`,
      // 7 days in nanoseconds
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      onSuccess: () => {
        initActor();
        setIsAuthenticated(true);
        setTimeout(() => {
          setHasLoggedIn(true);
        }, 100);
      },
    });
  };

  const initActor = () => {
    const actor = createMaster(canisterId as string, {
      agentOptions: {
        identity: authClient?.getIdentity(),
      },
    });
    setMaster(actor);
  }

  const logout = () => {
    authClient?.logout().then(() => {
      navigate("/");
      setIsAuthenticated(false);
      setMaster(godwin_master);
    });
  }

  const fetchSubs = async() => {
    let newSubs = new Map<string, Sub>();
    let listSubs = await master.listSubGodwins();
    for (let [principal, id] of listSubs) {
      let actor = createSub(principal, {
        agentOptions: {
          identity: authClient?.getIdentity(),
        },
      });
      let name = await actor.getName();
      let categories = await actor.getCategories();
      newSubs.set(id, {actor, name, categories});
    }
    setSubs(newSubs);
    setSubsFetched(true);
  }

  useEffect(() => {
    AuthClient.create({
      idleOptions: {
        disableDefaultIdleCallback: true,
        disableIdle: true
      }
    }).then(async (client) => {
      const isAuthenticated = await client.isAuthenticated();
      setAuthClient(client);
      setIsAuthenticated(isAuthenticated);
    });
  }, []);

  useEffect(() => {
    if (!subsFetched) {
      fetchSubs();
    }
  }, [subsFetched]);

  // Need to fetch subs when master changes, so the subs are logged in/out too
  useEffect(() => {
    fetchSubs();
  }, [master]);

  useEffect(() => {
    if (isAuthenticated) { initActor() };
  }, [isAuthenticated]);

  return {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    subsFetched,
    setSubsFetched,
    login,
    logout,
    token,
    master,
    subs,
    hasLoggedIn,
  };
}