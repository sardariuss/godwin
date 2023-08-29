import Header                          from "./Header";
import Footer                          from "./Footer";
import OpenQuestionPopup               from "./OpenQuestionPopup";
import MainQuestions                   from "./MainQuestions";
import CreateSub                       from "./CreateSub";
import UserComponent                   from "./user/User";
import ListSubs                        from "./ListSubs";
import { AuthProvider }                from "../ActorContext";

import { Route, Routes }               from "react-router-dom";

import React, { useState }             from "react";

function App() {

  const [showAskQuestion, setShowAskQuestion] = useState(false);

  return (
		<>
      <div className="flex flex-col min-h-screen w-full bg-white dark:bg-slate-900 dark:border-gray-700 justify-between">
        <AuthProvider>
          <div className="flex flex-col w-full">
            <Header setShowAskQuestion={setShowAskQuestion}/>
            <Routes>
              <Route
                path="/g/:subgodwin"
                element={ <MainQuestions/> }
              />
              <Route
                path="/profile/:user_principal"
                element={ <UserComponent/> }
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
          <OpenQuestionPopup showAskQuestion={showAskQuestion} setShowAskQuestion={setShowAskQuestion}></OpenQuestionPopup>
          <Footer/>
        </AuthProvider>
      </div>
    </>
  );
}

export default App;