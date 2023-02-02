import Header from "./Header";
import Footer from "./Footer";
import ListQuestions from "./ListQuestions";
import UserComponent from "./User";
import { ActorProvider } from "../ActorContext";

import { _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass, Actor, Identity, AnonymousIdentity } from "@dfinity/agent";

import { Route, Routes } from "react-router-dom";
import { useState, useEffect, useRef } from "react";

import { AuthClient } from "@dfinity/auth-client";
import { godwin_backend } from "./../../declarations/godwin_backend";

// @todo: manage logout and stay logged in on F5
function App() {
  
  const actor : ActorSubclass<_SERVICE> = godwin_backend;

  const [logged_in, setLoggedIn] = useState<boolean>(false);

  const login = async () => {

    let authClient = await createAuthClient();

    if (await authClient.isAuthenticated()){
      console.error("AuthClient is already authenticated");
      return;
    }
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
  }

  const handleAuthenticated = async (authClient: AuthClient) => {
    const identity = (await authClient.getIdentity()) as unknown as Identity;

    Actor.agentOf(actor)?.replaceIdentity?.(identity);

    setLoggedIn(true);
  }

  const createAuthClient = async() => {
    const authClient = await AuthClient.create({
      idleOptions: {
        idleTimeout: 1000 * 60 * 10, // set to 10 minutes
        disableDefaultIdleCallback: true,
        onIdle: async () => {
          await logout();
          console.log("You have been logged out due to inactivity");
        },
      },
    })

    const logout = async () => {
      await authClient.logout();
      setLoggedIn(false);
    }
    
    return authClient;
  }

  const refresh = async () => {
    let authClient = await createAuthClient();

    if (await authClient.isAuthenticated()){
      await handleAuthenticated(authClient);
    } else {
      setLoggedIn(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <ActorProvider value={{actor, logged_in}}>
          <div className="flex flex-col">    
            <Header login={login}/>
            <div className="border border-none">
            <Routes>
              <Route
                path="/"
                element={
                  <ListQuestions key={"list_interest"} order_by={{ 'INTEREST_SCORE' : null }} query_direction={{ 'BWD' : null }}/>
                }
              />
              <Route
                path="/opinion"
                element={
                  <ListQuestions key={"list_opinion"} order_by={{ 'STATUS' : { 'VOTING' : { 'OPINION' : null } }}} query_direction={{ 'FWD' : null }}/>
                }
              />
                <Route
                path="/categorization"
                element={
                  <ListQuestions key={"list_categorization"} order_by={{ 'STATUS' : { 'VOTING' : { 'CATEGORIZATION' : null } }}} query_direction={{ 'FWD' : null }}/>
                }
              />
                <Route
                path="/archives"
                element={
                  <ListQuestions key={"list_archive"} order_by={{ 'STATUS' : { 'CLOSED' : null } }} query_direction={{ 'FWD' : null }}/>
                }
              />
              <Route
                path="/rejected"
                element={
                  <ListQuestions key={"list_rejected"} order_by={{ 'STATUS' : { 'REJECTED' : null } }} query_direction={{ 'FWD' : null }}/>
                }
              />
              <Route
                path="/user"
                element={
                  <UserComponent/>
                }
              />
              </Routes>
            </div>
          </div>
          <Footer/>
        </ActorProvider>
      </div>
    </>
  );
}

export default App;