
import QuestionComponent from "./Question";
import { OrderBy, Direction, ScanLimitResult, Category, CategoryInfo, _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass } from "@dfinity/agent";

import { useEffect, useState } from "react";

type Results = {
  ids: bigint[],
  next : bigint | undefined,
}

const fromQuery = (query_result: ScanLimitResult) => {
  let ids = Array.from(query_result.keys);
  let [next] = query_result.next;
  return { ids, next };
}

export type ListQuestionsInput = {
  actor: ActorSubclass<_SERVICE>,
  categories: Map<Category, CategoryInfo>,
  order_by: OrderBy,
  query_direction: Direction
}

const ListQuestions = ({actor, categories, order_by, query_direction}: ListQuestionsInput) => {

  const [results, setResults] = useState<Results>({ ids : [], next: undefined});
  const [trigger_next, setTriggerNext] = useState<boolean>(false);
	
  const refreshQuestions = async () => {
    let query_result : ScanLimitResult = await actor.getQuestions(order_by, query_direction, BigInt(10), []);
    setResults(fromQuery(query_result));
  };

  const getNextQuestions = async () => {
    if (results.next !== undefined){
      let query_result : ScanLimitResult = await actor.getQuestions(order_by, query_direction, BigInt(10), [results.next]);
      let ids : bigint[] = [...new Set([...results.ids, ...Array.from(query_result.keys)])];
      let [next] = query_result.next;
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

  useEffect(() => {
    refreshQuestions();
  }, [order_by, query_direction]);

	return (
    <div className="w-full">
      {[...results.ids].map(id => (
        <li className="list-none" key={Number(id)}> 
          <QuestionComponent actor={actor} categories={categories} questionId={id}> </QuestionComponent>
        </li>
      ))}
    </div>
	);
};

export default ListQuestions;
