import { _SERVICE, Status, Polarization, Time, Appeal, CategoryInfo, Category } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../../ActorContext"
import { CategoriesContext } from "../../CategoriesContext"

import { useContext, useEffect, useState } from "react";

import { StatusEnum, statusToEnum, toMap } from "../../utils";

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
  
  const [interestAggregates, setInterestAggregates] = useState<Appeal[]>([]);
  const [interestPoints, setInterestPoints] = useState<bigint | undefined>(undefined);
  const [interestWinnerSymbol, setInterestWinnerSymbol] = useState<string | undefined>(undefined);

  const [opinionAggregates, setOpinionAggregates] = useState<Polarization[]>([]);
  const [opinionWinningRatio, setOpinionWinningRatio] = useState<number | undefined>(undefined);
  const [opinionWinnerSymbol, setOpinionWinnerSymbol] = useState<string | undefined>(undefined);

  const [categorizationAggregates, setCategorizationAggregates] = useState<Map<Category, Polarization>[]>([]);
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
    setInterestAggregates(appeals);

    if (appeals.length > 0) {
      let last_interest = appeals[appeals.length - 1];
      setInterestPoints(last_interest.score);
      setInterestWinnerSymbol(last_interest.ups > last_interest.downs ? "🤓" : "🤡");
    }
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
    setOpinionAggregates(opAggregates);
    setCategorizationAggregates(catAggregates);

    if (opAggregates.length > 0) {
      let last_opinion = opAggregates[opAggregates.length - 1];
      let total = last_opinion.left + last_opinion.center + last_opinion.right;
      if (last_opinion.left > last_opinion.center && last_opinion.left > last_opinion.right) {
        setOpinionWinningRatio(last_opinion.left / total);
        setOpinionWinnerSymbol("👎");
      } else if (last_opinion.right > last_opinion.center && last_opinion.right > last_opinion.left) {
        setOpinionWinningRatio(last_opinion.right / total);
        setOpinionWinnerSymbol("👍");
      } else {
        setOpinionWinningRatio(last_opinion.center / total);
        setOpinionWinnerSymbol("🤷");
      }
    }

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

  const opinion_info : CategoryInfo = {
    left: {
      symbol: "👎",
      name: "DISAGREE",
      color: "#0F9D58"
    },
    right: {
      symbol: "👍",
      name: "AGREE",
      color: "#DB4437"
    }
  }

	return (
    <div>
      <div>
        <ul className="hidden text-sm font-medium text-center text-gray-500 rounded-lg shadow sm:flex divide-x divide-gray-200 dark:divide-gray-700 dark:text-gray-400">
          <li className="w-full" onClick={()=> setCurrentAggregate(AggregateType.INTEREST)}>
            <div className={"inline-block w-full p-4 bg-white rounded-l-lg focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (interestWinnerSymbol !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
              <div className="text-xl">{ interestWinnerSymbol !== undefined ? interestWinnerSymbol : "." }</div>
              <div className={ interestPoints !== undefined ? "" : "text-transparent"}>{ interestPoints !== undefined ? interestPoints + " points" : "n/a" } </div>
            </div>
          </li>
          <li className="w-full" onClick={()=> setCurrentAggregate(AggregateType.OPINION)}>
            <div className={"inline-block w-full p-4 bg-white focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (opinionWinnerSymbol !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
              <div className="text-xl">{ opinionWinnerSymbol !== undefined ? opinionWinnerSymbol : "." }</div>
              <div className={ opinionWinningRatio !== undefined ? "" : "text-transparent"}>{ opinionWinningRatio !== undefined ? Math.round(opinionWinningRatio * 100) + "%" : "n/a" } </div>
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
          currentAggregate === AggregateType.INTEREST && interestAggregates[0] !== undefined ?
            <AppealComponent appeal={interestAggregates[0]}></AppealComponent> : <></>
        }
        </div>
        <div>
        {
          // @todo: take the last iteration
          currentAggregate === AggregateType.OPINION && opinionAggregates[0] !== undefined ?
            <PolarizationComponent category={"OPINION"} categoryInfo={opinion_info} showCategory={false} polarization={opinionAggregates[0]} centerSymbol={"🤷"}></PolarizationComponent>
          : <></>
        }
        </div>
        <ol>
        {
          // @todo: take the last iteration
          currentAggregate === AggregateType.CATEGORIZATION && categorizationAggregates[0] !== undefined ? (
          [...Array.from(categories.entries())].map((elem) => (
            <li key={elem[0]}>
              <PolarizationComponent category = {elem[0]} categoryInfo={elem[1]} showCategory={true} polarization={categorizationAggregates[0].get(elem[0])} centerSymbol={"🙏"}></PolarizationComponent>
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
