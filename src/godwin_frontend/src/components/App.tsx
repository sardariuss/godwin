import Header                          from "./Header";
import Footer                          from "./Footer";
import MainQuestions                   from "./MainQuestions";
import CreateSub                       from "./CreateSub";
import UserComponent                   from "./user/User";
import SubProfile                      from "./user/SubProfile";
import ListSubs                        from "./ListSubs";
import { ActorContext, useAuthClient } from "../ActorContext";

import { Route, Routes }               from "react-router-dom";

function App() {
  
  const {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    refreshSubs,
    addSub,
    login,
    logout,
    token,
    airdrop,
    master,
    subs,
    userAccount,
    balance,
    refreshBalance,
    loggedUserName,
    refreshLoggedUserName,
    getPrincipal
  } = useAuthClient();

  if (!authClient) return null;

  return (
		<>
      <div className="flex flex-col min-h-screen w-full bg-white dark:bg-slate-900 dark:border-gray-700 justify-between">
        <ActorContext.Provider value={{
          authClient,
          setAuthClient,
          isAuthenticated,
          setIsAuthenticated,
          refreshSubs,
          addSub,
          login,
          logout,
          token,
          airdrop,
          master,
          subs,
          userAccount,
          balance,
          refreshBalance,
          loggedUserName,
          refreshLoggedUserName,
          getPrincipal
        }}>
          <div className="flex flex-col w-full flex-grow">
            <Header/>
            <Routes>
              <Route
                path="/g/:subgodwin"
                element={ <MainQuestions/> }
              />
              <Route
                path="/user/:user"
                element={ <UserComponent/> }
              />
              <Route
                path="/g/:subgodwin/user/:user"
                element={ <SubProfile/> }
              />
              <Route
                path="/"
                element={ <ListSubs/> }
              />
              <Route
                path="/newsub"
                element={ <CreateSub/> }
              />
            </Routes>
          </div>
          <Footer/>
        </ActorContext.Provider>
      </div>
    </>
  );
}

export default App;