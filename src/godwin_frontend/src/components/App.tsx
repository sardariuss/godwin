import Header from "./Header";
import Footer from "./Footer";
import ListWrapper from "./ListWrapper";
import QuestionComponent from "./Question";

import { godwin_backend } from "../../../declarations/godwin_backend";


import { Route, Routes, HashRouter } from "react-router-dom";
import { useEffect, useState } from "react";

function App() {

  const [questions, setQuestions] = useState(new Map());

  const refreshQuestions = async () => {
    let result = await godwin_backend.getQuestions('INTEREST', 'bwd', 10);
    if (result.ok){
      let list_questions = result.ok;
      setQuestions(new Map([questions, list_questions.map(question => [question.id, question.title] as [number, string])]));
    } else {
      console.log("No question returned");
    };
  };

  useEffect(() => {
    refreshQuestions();
  }, []);

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <HashRouter>
          <div className="flex flex-col justify-start">
            <Header/>
            {[...questions.keys()].map(k => (
              <li key={k}> {questions.get(k)} </li>
            ))}
          </div>
          <Footer/>
        </HashRouter>
      </div>
    </>
  );
}

export default App;