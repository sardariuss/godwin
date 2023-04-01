import Header from "./Header";
import Footer from "./Footer";
import ListQuestions from "./ListQuestions";
import UserComponent from "./User";
import OpenQuestion from "./OpenQuestion";
import { Principal } from "@dfinity/principal";
import { ActorContext, useAuthClient } from "../ActorContext2";
import { CategoriesContext, useCategories } from "../CategoriesContext";
import { ActorSubclass, Identity, Actor } from "@dfinity/agent";

import { Route, Routes } from "react-router-dom";

import { useState, useEffect } from "react";

function App() {
  
  const {
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
  } = useAuthClient();

  const [names, setNames] = useState<Map<Principal, string>>(new Map());

  const fetchNames = async () => {
    let map = new Map<Principal, string>();
    for (const [principal, actor] of subs.entries()) {
      console.log("get name!")
      let name = await actor.getName();
      map.set(principal, name);
    }
    setNames(map);
	};

  useEffect(() => {
    if (subsFetched){
      fetchNames();
    }
  }, [subsFetched]);

  useEffect(() => {
    setSubsFetched(false);
  }, []);

  if (!authClient) return null;

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <ActorContext.Provider value={{
          authClient,
          setAuthClient,
          isAuthenticated,
          setIsAuthenticated,
          login,
          logout,
          master,
          hasLoggedIn,
        }}>
          <div className="flex flex-col">
            <Header login={login} setShowAskQuestion={() => {}}/>
            <div className="grid grid-cols-4 gap-4 w-full m-10">
              {
                [...Array.from(names.entries())].map((elem) => (
                  <a href="#" className="block max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700">
                    <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{elem[1]}</h5>
                    <p className="font-normal text-gray-700 dark:text-gray-400">6 dimensions</p>
                    <p className="font-normal text-gray-700 dark:text-gray-400">512 active users</p>
                  </a>
                ))
              }
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
              <a href="#" className="block h-36 max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"/>
            </div>
          </div>
          <Footer/>
        </ActorContext.Provider>
      </div>
    </>
  );
}

export default App;