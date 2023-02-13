import Header from "./Header";
import Footer from "./Footer";
import ListQuestions from "./ListQuestions";
import UserComponent from "./User";
import { ActorContext, useAuthClient } from "../ActorContext";

import { _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { Route, Routes } from "react-router-dom";


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
        </ActorContext.Provider>
      </div>
    </>
  );
}

export default App;