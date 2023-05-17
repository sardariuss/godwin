
import QuestionComponent from "./Question";

import { useEffect, useState } from "react";

import { ScanResults, toMap } from "../utils";

import { Sub } from "../ActorContext";

export type ListQuestionsInput = {
  sub: Sub,
  query_questions: (next: bigint | undefined) => Promise<ScanResults<bigint>>,
}

export const ListQuestions = ({sub, query_questions}: ListQuestionsInput) => {

  const [results, setResults] = useState<ScanResults<bigint>>({ ids : [], next: undefined});
  const [trigger_next, setTriggerNext] = useState<boolean>(false);
	
  const refreshQuestions = async () => {
    setResults(await query_questions(undefined));
  };

  const getNextQuestions = async () => {
    if (results.next !== undefined){
      let query_result = await query_questions(results.next);
      setResults({ 
        ids: [...new Set([...results.ids, ...Array.from(query_result.ids)])],
        next: query_result.next 
      });
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
  }, [query_questions]);

  useEffect(() => {
    if (trigger_next){
      setTriggerNext(false);
      getNextQuestions();
    };
  }, [trigger_next]);

	return (
    <div className="w-full">
      {[...results.ids].map(id => (
        <li className="list-none" key={Number(id)}> 
          <QuestionComponent actor={sub.actor} categories={toMap(sub.categories)} questionId={id}> </QuestionComponent>
        </li>
      ))}
    </div>
	);
};

export default ListQuestions;
