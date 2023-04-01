import { AuthClient, IdbStorage } from "@dfinity/auth-client";
import { DelegationChain, isDelegationValid } from "@dfinity/identity";

import { _SERVICE as MasterService } from "../declarations/godwin_master/godwin_master.did";
import { _SERVICE as SubService } from "../declarations/godwin_backend/godwin_backend.did";
import { canisterId, createActor as createMaster, godwin_master } from "../declarations/godwin_master";
import { createActor as createSub } from "../declarations/godwin_backend";
import { ActorSubclass } from "@dfinity/agent";

import { useState, useEffect } from "react";

import { useNavigate } from "react-router-dom";

import React from 'react'
import { Principal } from "@dfinity/principal";

export const ActorContext = React.createContext<{
  authClient?: AuthClient;
  setAuthClient?: React.Dispatch<AuthClient>;
  isAuthenticated?: boolean | null;
  setIsAuthenticated?: React.Dispatch<React.SetStateAction<boolean | null>>;
  subsFetched?: boolean | null;
  setSubsFetched?: React.Dispatch<React.SetStateAction<boolean | null>>;
  login: () => void;
  logout: () => void;
  master: ActorSubclass<MasterService>;
  subs: Map<Principal, ActorSubclass<SubService>>;
  hasLoggedIn: boolean;
}>({
  login: () => {},
  logout: () => {},
  master: godwin_master,
  subs: new Map(),
  hasLoggedIn: false
});

export async function checkDelegation() {
  const delegations = await new IdbStorage().get("ic-delegation");
  if (!delegations) return false;
  const chain = DelegationChain.fromJSON(delegations);
  return isDelegationValid(chain);
}

export function useAuthClient() {
  const navigate = useNavigate();

  const [authClient, setAuthClient] = useState<AuthClient>();
  const [isAuthenticated, setIsAuthenticated] = useState<null | boolean>(null);
  const [hasLoggedIn, setHasLoggedIn] = useState(false);
  const [master, setMaster] = useState<ActorSubclass<MasterService>>(godwin_master);
  const [subs, setSubs] = useState<Map<Principal, ActorSubclass<SubService>>>(new Map());
  const [subsFetched, setSubsFetched] = useState(true);

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
        // @todo
        //let identity = authClient.getIdentity() as unknown as Identity;
        //Actor.agentOf(actor)?.replaceIdentity?.(identity);
        setIsAuthenticated(true);
        setTimeout(() => {
          setHasLoggedIn(true);
        }, 100);
      },
    });
  };

  const initActor = () => {
    console.log("INIT ACTOR");
    const actor = createMaster(canisterId as string, {
      agentOptions: {
        identity: authClient?.getIdentity(),
      },
    });
    setMaster(actor);
  }

  const logout = () => {
    navigate("/");
    setIsAuthenticated(false);
    setMaster(godwin_master);
    authClient?.logout().then(() => { console.log("LOGGED OUT") });
  }

  const refreshSubs = async() => {
    let newSubs = new Map<Principal, ActorSubclass<SubService>>();
    for (let id of subs.keys()) {
      let actor = createSub(id, {
        agentOptions: {
          identity: authClient?.getIdentity(),
        },
      });
      newSubs.set(id, actor);
    }
    setSubs(newSubs);
  }

  const fetchSubs = async() => {
    let toAdd = new Map<Principal, ActorSubclass<SubService>>();
    let ids = await master.listSubGodwins();
    for (let id of ids) {
      if (!subs.has(id)){
        console.log("Add sub! " + id.toText());
        let actor = createSub(id, {
          agentOptions: {
            identity: authClient?.getIdentity(),
          },
        });
        toAdd.set(id, actor);
      }
    }
    setSubs(new Map([...subs, ...toAdd]));
    setSubsFetched(true);
  }

  useEffect(() => {
    // @todo: what is that
    checkDelegation().then((valid) => {
      if (valid) {
        console.log("DELEGATION IS VALID");
      } else {
        console.log("DELEGATION IS NOT VALID");
      };
    });

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

  useEffect(() => {
    refreshSubs();
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
    master,
    subs,
    hasLoggedIn,
  };
}