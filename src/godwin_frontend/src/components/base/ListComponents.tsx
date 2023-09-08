import Spinner                        from "../Spinner";
import { ScanResults }                from "../../utils";
import { Direction, }                 from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useEffect, useState } from "react";

export type ListComponentsInput<T, Input> = {
  query_components: (direction: Direction, limit: bigint, next: T | undefined) => Promise<ScanResults<T>>,
  generate_input: (T) => Input,
  build_component: (input: Input) => JSX.Element,
  generate_key: (T) => string,
  empty_list_message: () => string,
};

export const ListComponents = <T, Input>({query_components, generate_input, build_component, generate_key, empty_list_message}: ListComponentsInput<T, Input>) => {

  const direction = { 'BWD' : null };
  const limit = BigInt(10);

  const [initialized,  setInitialized] = useState<boolean>       (false                       );
  const [results,      setResults    ] = useState<ScanResults<T>>({ ids : [], next: undefined});
  const [trigger_next, setTriggerNext] = useState<boolean>       (false                       );
	
  const refreshComponents = async () => {
    let res = await query_components(direction, limit, undefined);
    setResults(old => { return { 
      ids: [...new Set([...res.ids])],
      next: res.next 
    }});
  };

  const getNextComponents = async () => {
    if (results.next !== undefined){
      let query_result = await query_components(direction, limit, results.next);
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
    refreshComponents();
    setInitialized(true);
    window.addEventListener('scroll', scrolling, {passive: true});
    return () => {
      window.removeEventListener('scroll', scrolling);
    };
  }, [query_components]);
  
  useEffect(() => {
    if (trigger_next){
      setTriggerNext(false);
      getNextComponents();
    };
  }, [trigger_next]);
  
	return (
    <div className="flex flex-col items-center w-full flex-grow">
      {
        !initialized? 
          <div className="w-6 h-6 mt-4">
            <Spinner/>
          </div> :
        results.ids.length === 0 ?
          <div className="text-black dark:text-white text-sm mt-5 my-2 flex-grow">
            { empty_list_message() }
          </div> :
        <ol className="w-full flex flex-col">
          {[...results.ids].map((element) => (
            <li key={generate_key(element)}>
            {
              React.createElement(build_component, generate_input(element))
            }
            </li>
          ))}
        </ol>
      }
    </div>
	);
};

export default ListComponents;
