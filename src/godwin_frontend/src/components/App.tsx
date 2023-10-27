import Header                          from "./Header";
import Footer                          from "./Footer";
import MainQuestions                   from "./MainQuestions";
import CreateSub                       from "./CreateSub";
import UserComponent                   from "./user/User";
import SubProfile                      from "./user/SubProfile";
import ListSubs                        from "./ListSubs";
import RequireAuth                     from "./RequireAuth";
import Welcome                         from "./Welcome";
import { ActorContext, useAuthClient } from "../ActorContext";

import { Route, Routes }               from "react-router-dom";

function App() {
  
  const {
    authClient,
    isAuthenticated,
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
      <ActorContext.Provider value={{
        authClient,
        isAuthenticated,
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
        <div className="flex flex-col min-h-screen w-full bg-white dark:bg-slate-900 dark:border-gray-700 flex-grow">
          <Header/>
          <Routes>
            <Route element={ <RequireAuth isAuthenticated={ isAuthenticated === true }/> }>
              <Route
                path="/"
                element={ <ListSubs/> }
              />
              <Route
                path="/sub/:subgodwin"
                element={ <MainQuestions/> }
              />
              <Route
                path="/user/:user"
                element={ <UserComponent/> }
              />
              <Route
                path="/sub/:subgodwin/user/:user"
                element={ <SubProfile/> }
              />
              <Route
                path="/newsub"
                element={ <CreateSub/> }
              />
            </Route>
            <Route
                path="/login"
                element={ <Welcome/> }
            />
          </Routes>
        </div>
        <Footer/>
      </ActorContext.Provider>
    </>
  );
}

export default App;