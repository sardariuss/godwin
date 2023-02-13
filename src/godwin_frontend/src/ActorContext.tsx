import { AuthClient, IdbStorage } from "@dfinity/auth-client";
import { DelegationChain, isDelegationValid } from "@dfinity/identity";

import { _SERVICE } from "../declarations/godwin_backend/godwin_backend.did";
import { canisterId, createActor, godwin_backend } from "../declarations/godwin_backend";
import { ActorSubclass, Identity, Actor } from "@dfinity/agent";

import { useState, useEffect } from "react";

import { useNavigate } from "react-router-dom";

import React from 'react'

export const ActorContext = React.createContext<{
  authClient?: AuthClient;
  setAuthClient?: React.Dispatch<AuthClient>;
  isAuthenticated?: boolean | null;
  setIsAuthenticated?: React.Dispatch<React.SetStateAction<boolean | null>>;
  login: () => void;
  logout: () => void;
  actor: ActorSubclass<_SERVICE>;
  hasLoggedIn: boolean;
}>({
  login: () => {},
  logout: () => {},
  actor: godwin_backend,
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
  const [actor, setActor] = useState<ActorSubclass<_SERVICE>>(godwin_backend);
  const [isAuthenticated, setIsAuthenticated] = useState<null | boolean>(null);
  const [hasLoggedIn, setHasLoggedIn] = useState(false);

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
    const actor = createActor(canisterId as string, {
      agentOptions: {
        identity: authClient?.getIdentity(),
      },
    });
    setActor(actor);
  }

  const logout = () => {
    navigate("/");
    setIsAuthenticated(false);
    setActor(godwin_backend);
    authClient?.logout().then(() => { console.log("LOGGED OUT") });
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
    if (isAuthenticated) { initActor() };
  }, [isAuthenticated]);

  return {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    login,
    logout,
    actor,
    hasLoggedIn,
  };
}