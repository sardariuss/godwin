import Header from "./Header";
import Footer from "./Footer";
import QuestionComponent from "./Question";

import { QueryQuestionsResult } from "../../../declarations/godwin_backend/godwin_backend.did";

import { godwin_backend } from "../../../declarations/godwin_backend";

import { Route, Routes, HashRouter } from "react-router-dom";
import { useEffect, useState } from "react";

type Results = {
  ids: number[],
  next : number | undefined,
}

const fromQuery = (query_result: QueryQuestionsResult) => {
  let ids = Array.from(query_result.ids);
  let [next] = query_result.next_id;
  return { ids, next };
}

function App() {
  const [results, setResults] = useState<Results>({ ids : [], next: undefined});
  const [trigger_next, setTriggerNext] = useState<boolean>(false);

  const refreshQuestions = async () => {
    let query_result : QueryQuestionsResult = await godwin_backend.getQuestions({ 'INTEREST' : null }, { 'bwd' : null }, 10, []);
    setResults(fromQuery(query_result));
  };

  const getNextQuestions = async () => {
    if (results.next !== undefined){
      let query_result : QueryQuestionsResult = await godwin_backend.getQuestions({ 'INTEREST' : null }, { 'bwd' : null }, 10, [results.next]);
      let ids : number[] = [...new Set([...results.ids, ...Array.from(query_result.ids)])];
      let [next] = query_result.next_id;
      setResults({ ids, next });
    }
  };

  const atEnd = () => {
    var c = [document.scrollingElement.scrollHeight, document.body.scrollHeight, document.body.offsetHeight].sort(function(a,b){return b-a}) // select longest candidate for scrollable length
    return (window.innerHeight + window.scrollY + 2 >= c[0]) // compare with scroll position + some give
  }

  const scrolling = () => {
      if (atEnd()) {
        setTriggerNext(true);
      }
  }

  useEffect(() => {
    refreshQuestions();
    window.addEventListener('scroll', scrolling, {passive: true});
    return () => {
      window.removeEventListener('scroll', scrolling);
    };
  }, []);

  useEffect(() => {
    if (trigger_next){
      setTriggerNext(false);
      getNextQuestions();
    };
  }, [trigger_next]);

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <HashRouter>
          <div className="flex flex-col">
            <Header/>
            <div className="border border-none mx-96 my-16 justify-center">
              {[...results.ids].map(question_id => (
                <li className="list-none" key={question_id}> 
                  <QuestionComponent id={question_id}> </QuestionComponent>
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