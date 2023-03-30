import { _SERVICE, Status, Polarization, Time, Appeal, CategoryInfo, Category } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../../ActorContext"
import { CategoriesContext } from "../../CategoriesContext"

import CONSTANTS from "../../Constants";

import { useContext, useEffect, useState } from "react";

import { StatusEnum, polarizationToCursor, getCursorInfo, toMap, toPolarizationInfo } from "../../utils";

import PolarizationComponent from "./Polarization";
import AppealComponent from "./Appeal";

type Props = {
  questionId: bigint,
  statusHistory: Map<StatusEnum, Array<Time>> | undefined
};

enum SideEnum {
  LEFT,
  RIGHT
};

enum AggregateType {
  INTEREST,
  OPINION,
  CATEGORIZATION
};

const Aggregates = ({ questionId, statusHistory }: Props) => {

  const {actor} = useContext(ActorContext);
  const {categories} = useContext(CategoriesContext);

  const [currentAggregate, setCurrentAggregate] = useState<AggregateType>(AggregateType.OPINION);
  
  const [interestAggregate, setInterestAggregate] = useState<Appeal | undefined>();

  const [opinionAggregate, setOpinionAggregate] = useState<Polarization | undefined>();

  const [categorizationAggregate, setCategorizationAggregate] = useState<Map<Category, Polarization> | undefined>();
  const [categorizationWinningRatio, setCategorizationWinningRatio] = useState<number | undefined>(undefined);
  const [categorizationWinnerSymbol, setCategorizationWinnerSymbol] = useState<string | undefined>(undefined);

  const fetchCandidateStatusVotes = async () => {
    let appeals : Appeal[] = [];
    if (statusHistory !== undefined) {
      let history_dates = statusHistory.get(StatusEnum.CANDIDATE);
      let num_iterations = history_dates !== undefined ? history_dates.length : 0;
      for (let iteration = 0; iteration < num_iterations; iteration++) {
        let vote = await actor.revealInterestVote(questionId, BigInt(iteration));
        if (vote['ok'] !== undefined) {
          appeals.push(vote['ok'].aggregate);
        };
      };
    };
    setInterestAggregate(appeals[appeals.length - 1]);
  };

  const fetchOpenStatusVotes = async () => {
    let opAggregates : Polarization[] = [];
    let catAggregates : Map<Category, Polarization>[] = [];
    if (statusHistory !== undefined) {
      let history_dates = statusHistory.get(StatusEnum.OPEN);
      let num_iterations = history_dates !== undefined ? history_dates.length : 0;
      for (let iteration = 0; iteration < num_iterations; iteration++) {
        let opVote = await actor.revealOpinionVote(questionId, BigInt(iteration));
        if (opVote['ok'] !== undefined) {
          opAggregates.push(opVote['ok'].aggregate);
        };
        let catVote = await actor.revealCategorizationVote(questionId, BigInt(iteration));
        if (catVote['ok'] !== undefined) {
          catAggregates.push(toMap(catVote['ok'].aggregate));
        }
      }
    }
    setOpinionAggregate(opAggregates[opAggregates.length - 1]);
    setCategorizationAggregate(catAggregates[catAggregates.length - 1]);

    if (catAggregates.length > 0) {
      let last_categorization = catAggregates[catAggregates.length - 1];
      let max_ratio = 0;
      let winning_dimension: [string, Polarization] | undefined = undefined;
      let winning_side = SideEnum.LEFT;
      last_categorization.forEach((polarization, dimension) => {
        let num_votes = polarization.left + polarization.center + polarization.right;
        let ratio_left = polarization.left / num_votes;
        let ratio_right = polarization.right / num_votes;

        if (ratio_left >= max_ratio || ratio_right > max_ratio) {
          winning_dimension = [dimension, polarization];
          if (ratio_left >= ratio_right) {
            winning_side = SideEnum.LEFT;
            max_ratio = ratio_left;
          } else {
            winning_side = SideEnum.RIGHT;
            max_ratio = ratio_right;
          }
        }
      });

      if (winning_dimension !== undefined) {
        if (max_ratio > 0.33) {
          setCategorizationWinningRatio(max_ratio);
          switch(winning_side) {
            case SideEnum.LEFT: setCategorizationWinnerSymbol(categories.get(winning_dimension[0])?.left.symbol); break;
            case SideEnum.RIGHT: setCategorizationWinnerSymbol(categories.get(winning_dimension[0])?.right.symbol); break;
          }
        } else {
          let polarization = winning_dimension[1];
          let num_votes = polarization.left + polarization.center + polarization.right;
          setCategorizationWinningRatio(polarization.center / num_votes);
          setCategorizationWinnerSymbol("🙏");
        }
      }
    }
  };

  useEffect(() => {
    fetchCandidateStatusVotes();
    fetchOpenStatusVotes();
  }, []);

  useEffect(() => {
    fetchCandidateStatusVotes();
    fetchOpenStatusVotes();
  }, [statusHistory]);

	return (
    <div>
      <div>
        <ul className="hidden text-sm font-medium text-center text-gray-500 rounded-lg shadow sm:flex divide-x divide-gray-200 dark:divide-gray-700 dark:text-gray-400">
          <li className="w-full" onClick={()=> setCurrentAggregate(AggregateType.INTEREST)}>
            <div className={"inline-block w-full p-4 bg-white rounded-l-lg focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (interestAggregate !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
              <div className="text-xl">{ interestAggregate !== undefined ? interestAggregate.ups > interestAggregate.downs ? "🤓" : "🤡" : "." }</div>
              <div className={ interestAggregate !== undefined ? "" : "text-transparent"}>{ interestAggregate !== undefined ? interestAggregate.score + " points" : "n/a" } </div>
            </div>
          </li>
          <li className="w-full" onClick={()=> setCurrentAggregate(AggregateType.OPINION)}>
            <div className={"inline-block w-full p-4 bg-white focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (opinionAggregate !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
              <div className="text-xl">{ opinionAggregate !== undefined ? getCursorInfo(polarizationToCursor(opinionAggregate), CONSTANTS.OPINION_INFO).symbol : "." }</div>
              <div className={ opinionAggregate !== undefined ? "" : "text-transparent"}>{ opinionAggregate !== undefined ? polarizationToCursor(opinionAggregate).toFixed(CONSTANTS.CURSOR_DECIMALS) : "n/a" } </div>
            </div>
          </li>
          <li className="w-full" onClick={()=> setCurrentAggregate(AggregateType.CATEGORIZATION)}>
            <div className={"inline-block w-full p-4 bg-white rounded-r-lg focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (categorizationWinnerSymbol !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
              <div className="text-xl">{ categorizationWinnerSymbol !== undefined ? categorizationWinnerSymbol : "." }</div>
              <div className={ categorizationWinningRatio !== undefined ? "" : "text-transparent"}>{ categorizationWinningRatio !== undefined ? Math.round(categorizationWinningRatio * 100) + "%" : "n/a" } </div>
            </div>
          </li>
        </ul>
      </div>
      <div>
        <div>
        {
          // @todo: take the last iteration
          currentAggregate === AggregateType.INTEREST && interestAggregate !== undefined ?
            <AppealComponent appeal={interestAggregate}></AppealComponent> : <></>
        }
        </div>
        <div>
        {
          // @todo: take the last iteration
          currentAggregate === AggregateType.OPINION && opinionAggregate !== undefined ?
            <PolarizationComponent name={"OPINION"} showName={false} polarizationInfo={CONSTANTS.OPINION_INFO} polarizationValue={opinionAggregate}></PolarizationComponent>
          : <></>
        }
        </div>
        <ol>
        {
          // @todo: take the last iteration
          currentAggregate === AggregateType.CATEGORIZATION && categorizationAggregate !== undefined ? (
          [...Array.from(categories.entries())].map((elem) => (
            <li key={elem[0]}>
              <PolarizationComponent name={elem[0]} showName={true} polarizationInfo={toPolarizationInfo(elem[1], CONSTANTS.CATEGORIZATION_INFO.center)} polarizationValue={categorizationAggregate.get(elem[0])}></PolarizationComponent>
            </li>
          ))
          ) : (
            <></>
          )
        }
        </ol>
      </div>
    </div>
	);
};

export default Aggregates;
