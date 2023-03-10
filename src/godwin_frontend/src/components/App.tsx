import Header from "./Header";
import Footer from "./Footer";
import ListQuestions from "./ListQuestions";
import UserComponent from "./User";
import OpenQuestion from "./OpenQuestion";
import { ActorContext, useAuthClient } from "../ActorContext";
import { CategoriesContext, useCategories } from "../CategoriesContext";

import { _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { Route, Routes } from "react-router-dom";

import { useState } from "react";


function App() {
  
  const {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    login,
    logout,
    actor,
    hasLoggedIn,
  } = useAuthClient();

  const {
    categories
  } = useCategories();

  const [showAskQuestion, setShowAskQuestion] = useState<boolean>(false);

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
          actor,
          hasLoggedIn,
        }}>
          <CategoriesContext.Provider value={{categories}}>
            <div className="flex flex-col">
              <Header login={login} setShowAskQuestion={setShowAskQuestion}/>
              <div className="border border-none">
              <Routes>
                <Route
                  path="/"
                  element={
                    <ListQuestions key={"list_interest"} order_by={{ 'INTEREST_SCORE' : null }} query_direction={{ 'BWD' : null }}/>
                  }
                />
                <Route
                  path="/open"
                  element={
                    <ListQuestions key={"list_opinion"} order_by={{ 'STATUS' : { 'OPEN' : null } }} query_direction={{ 'FWD' : null }}/>
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
            <div className="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true" hidden={!showAskQuestion}>
              <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
              <div className="fixed inset-0 z-10 overflow-y-auto">
                <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
                  <div className="relative transform overflow-hidden rounded-lg bg-gray-100 dark:bg-gray-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
                    <button type="button" className="text-gray-400 bg-transparent hover:bg-gray-50 hover:dark:bg-gray-700 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:text-white" onClick={(e) => setShowAskQuestion(false)}>
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd"></path></svg>  
                    </button>
                    <OpenQuestion setShowAskQuestion={setShowAskQuestion}></OpenQuestion>
                  </div>
                </div>
              </div>
            </div>
          </CategoriesContext.Provider>
        </ActorContext.Provider>
      </div>
    </>
  );
}

export default App;