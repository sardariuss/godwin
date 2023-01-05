import Header from "./Header";
import Footer from "./Footer";
import ListQuestions from "./ListQuestions";
import { ActorProvider } from "../ActorContext";

import { _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass, Actor, Identity, AnonymousIdentity } from "@dfinity/agent";

import { Route, Routes, HashRouter } from "react-router-dom";
import { useEffect, useState } from "react";

import { AuthClient } from "@dfinity/auth-client";
import { godwin_backend } from "./../../declarations/godwin_backend";

// @todo: manage logout and stay logged in on F5
function App() {
  
  const [actor, setActor] = useState<ActorSubclass<_SERVICE>>(godwin_backend);
  const [logged_in, setLoggedIn] = useState<boolean>(false);

  const login = async () => {
    const authClient = await AuthClient.create({
      idleOptions: {
        idleTimeout: 1000 * 60 * 5, // set to 5 minutes
        disableDefaultIdleCallback: true,
      }});

    authClient.login({
      // 7 days in nanoseconds
      identityProvider:
        process.env.DFX_NETWORK === "ic"
          ? "https://identity.ic0.app/#authorize"
          : `http://localhost:${process.env.REPLICA_PORT}?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID}#authorize`,
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      onSuccess: async () => {
        await handleAuthenticated(authClient);
      },
    });
  };

  const handleAuthenticated = async (authClient: AuthClient) => {
    const identity = (await authClient.getIdentity()) as unknown as Identity;

    setActor(actor => {
      Actor.agentOf(actor)?.replaceIdentity?.(identity);
      setLoggedIn(true);
      return actor;
    });

    // Invalidate identity then render login when user goes idle
    authClient.idleManager?.registerCallback(() => {
      setActor(actor => {
        Actor.agentOf(actor)?.replaceIdentity?.(new AnonymousIdentity());
        setLoggedIn(false);
        return actor;
      });
    });
  };

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <HashRouter>
          <ActorProvider value={{actor, logged_in}}>
            <div className="flex flex-col">    
              <Header login={login}/>
              <ListQuestions/>
            </div>
            <Footer/>
          </ActorProvider>
        </HashRouter>
      </div>
    </>
  );
}

export default App;