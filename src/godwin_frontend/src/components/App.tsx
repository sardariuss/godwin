import Header                          from "./Header";
import Footer                          from "./Footer";
import OpenQuestionPopup               from "./OpenQuestionPopup";
import MainQuestions                   from "./MainQuestions";
import UserComponent                   from "./user/User";
import ListSubs                        from "./ListSubs";
import { ActorContext, useAuthClient } from "../ActorContext";

import { Route, Routes }               from "react-router-dom";

import { useState }                    from "react";

function App() {

  const [showAskQuestion, setShowAskQuestion] = useState(false);
  
  const {
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
    userAccount,
    balance,
    refreshBalance,
    getPrincipal
  } = useAuthClient();

  if (!authClient) return null;

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 dark:border-gray-700 justify-between">
        <ActorContext.Provider value={{
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
          userAccount,
          balance,
          refreshBalance,
          getPrincipal
        }}>
          <div className="flex flex-col">
            <Header login={login} setShowAskQuestion={setShowAskQuestion}/>
            <Routes>
              <Route
                path="/g/:subgodwin"
                element={
                  <MainQuestions/>
                }
              />
                {
                  <Route
                    path="/profile/:user"
                    element={
                      <UserComponent/>
                    }
                  />
                }
              <Route
                path="/"
                element={
                  <ListSubs></ListSubs>
                }
              />      
            </Routes>
          </div>
          <OpenQuestionPopup showAskQuestion={showAskQuestion} setShowAskQuestion={setShowAskQuestion}></OpenQuestionPopup>
          <Footer/>
        </ActorContext.Provider>
      </div>
    </>
  );
}

export default App;