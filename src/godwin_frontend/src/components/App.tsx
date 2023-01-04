import Header from "./Header";
import Footer from "./Footer";
import QuestionComponent from "./Question";

import { godwin_backend } from "../../../declarations/godwin_backend";
import { Question } from "../../../declarations/godwin_backend/godwin_backend.did";

import { Route, Routes, HashRouter } from "react-router-dom";
import { useEffect, useState } from "react";

function App() {

  const [questions, setQuestions] = useState(new Map());

  const refreshQuestions = async () => {
    let list_questions = await godwin_backend.getQuestions({ 'INTEREST' : null }, { 'bwd' : null }, 10);
    if (list_questions.size == 0){
      console.log("No question returned");
    } else {
      setQuestions(new Map(list_questions.map(question => [question.id, question] as [number, Question])));
    }
  };

  useEffect(() => {
    refreshQuestions();
  }, []);

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <HashRouter>
          <div className="flex flex-col">
            <Header/>
            <div className="border border-none mx-96 my-16 justify-center">
              {[...questions.keys()].map(k => (
                <li className="list-none" key={k}> 
                  <QuestionComponent question={questions.get(k)}> </QuestionComponent>
                </li>
              ))}
            </div>
          </div>
          <Footer/>
        </HashRouter>
      </div>
    </>
  );
}

export default App;