import { _SERVICE, Status, Polarization, Time, PublicVote, PublicVote_1, PublicVote_2 } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../../ActorContext"
import { CategoriesContext } from "../../CategoriesContext"

import { useContext, useEffect, useState } from "react";

import { StatusEnum, statusToEnum } from "../../utils";

type Props = {
  questionId: bigint,
  statusHistory: Map<StatusEnum, Array<Time>> | undefined
};

enum SideEnum {
  LEFT,
  RIGHT
};

const Aggregates = ({ questionId, statusHistory }: Props) => {

  const {actor} = useContext(ActorContext);
  const {categories} = useContext(CategoriesContext);
  
  const [interestVotes, setInterestVotes] = useState<PublicVote_1[]>([]);
  const [interestPoints, setInterestPoints] = useState<bigint | undefined>(undefined);
  const [interestWinnerSymbol, setInterestWinnerSymbol] = useState<string | undefined>(undefined);

  const [opinionVotes, setOpinionVotes] = useState<PublicVote[]>([]);
  const [opinionWinningRatio, setOpinionWinningRatio] = useState<number | undefined>(undefined);
  const [opinionWinnerSymbol, setOpinionWinnerSymbol] = useState<string | undefined>(undefined);

  const [categorizationVotes, setCategorizationVotes] = useState<PublicVote_2[]>([]);
  const [categorizationWinningRatio, setCategorizationWinningRatio] = useState<number | undefined>(undefined);
  const [categorizationWinnerSymbol, setCategorizationWinnerSymbol] = useState<string | undefined>(undefined);

  const fetchCandidateStatusVotes = async () => {
    let votes : PublicVote_1[] = [];
    if (statusHistory !== undefined) {
      let history_dates = statusHistory.get(StatusEnum.CANDIDATE);
      let num_iterations = history_dates !== undefined ? history_dates.length : 0;
      for (let iteration = 0; iteration < num_iterations; iteration++) {
        let vote = await actor.getInterestVote(questionId, BigInt(iteration));
        if (vote[0] !== undefined) {
          votes.push(vote[0]);
        };
      };
    };
    setInterestVotes(votes);

    if (votes.length > 0) {
      let last_interest = votes[votes.length - 1];
      setInterestPoints(last_interest.aggregate.score);
      setInterestWinnerSymbol(last_interest.aggregate.ups > last_interest.aggregate.downs ? "🤓" : "🤡");
    }
  };

  const fetchOpenStatusVotes = async () => {
    let opVotes : PublicVote[] = [];
    let catVotes : PublicVote_2[] = [];
    if (statusHistory !== undefined) {
      let history_dates = statusHistory.get(StatusEnum.OPEN);
      let num_iterations = history_dates !== undefined ? history_dates.length : 0;
      for (let iteration = 0; iteration < num_iterations; iteration++) {
        let opVote = await actor.getOpinionVote(questionId, BigInt(iteration));
        if (opVote[0] !== undefined) {
          opVotes.push(opVote[0]);
        };
        let catVote = await actor.getCategorizationVote(questionId, BigInt(iteration));
        if (catVote[0] !== undefined) {
          catVotes.push(catVote[0]);
        }
      };
    };
    setOpinionVotes(opVotes);
    setCategorizationVotes(catVotes);

    if (opVotes.length > 0) {
      let last_opinion = opVotes[opVotes.length - 1];
      let opinion_aggregate = last_opinion.aggregate;
      let total = opinion_aggregate.left + opinion_aggregate.center + opinion_aggregate.right;
      if (opinion_aggregate.left > opinion_aggregate.center && opinion_aggregate.left > opinion_aggregate.right) {
        setOpinionWinningRatio(opinion_aggregate.left / total);
        setOpinionWinnerSymbol("👎");
      } else if (opinion_aggregate.right > opinion_aggregate.center && opinion_aggregate.right > opinion_aggregate.left) {
        setOpinionWinningRatio(opinion_aggregate.right / total);
        setOpinionWinnerSymbol("👍");
      } else {
        setOpinionWinningRatio(opinion_aggregate.center / total);
        setOpinionWinnerSymbol("🤷");
      }
    }

    if (catVotes.length > 0) {
      let last_categorization = catVotes[catVotes.length - 1];
      let cat_aggregate = last_categorization.aggregate;
      let max_ratio = 0;
      let winning_dimension: [string, Polarization] | undefined = undefined;
      let winning_side = SideEnum.LEFT;
      for (let i = 0; i < cat_aggregate.length; i++) {
        let dim_aggregate = cat_aggregate[i];
        let polarization = dim_aggregate[1];
        let num_votes = polarization.left + polarization.center + polarization.right;
        let ratio_left = polarization.left / num_votes;
        let ratio_right = polarization.right / num_votes;

        if (ratio_left >= max_ratio || ratio_right > max_ratio) {
          winning_dimension = dim_aggregate;
          if (ratio_left >= ratio_right) {
            winning_side = SideEnum.LEFT;
            max_ratio = ratio_left;
          } else {
            winning_side = SideEnum.RIGHT;
            max_ratio = ratio_right;
          }
        }
      }

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
      <ul className="hidden text-sm font-medium text-center text-gray-500 rounded-lg shadow sm:flex divide-x divide-gray-200 dark:divide-gray-700 dark:text-gray-400">
        <li className="w-full">
        <div className={"inline-block w-full p-4 bg-white rounded-l-lg focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (interestWinnerSymbol !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
            <div>{ interestWinnerSymbol !== undefined ? interestWinnerSymbol : "." }</div>
            <div className={ interestPoints !== undefined ? "" : "text-transparent"}>{ interestPoints !== undefined ? interestPoints + " points" : "n/a" } </div>
          </div>
        </li>
        <li className="w-full">
          <div className={"inline-block w-full p-4 bg-white focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (opinionWinnerSymbol !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
            <div>{ opinionWinnerSymbol !== undefined ? opinionWinnerSymbol : "." }</div>
            <div className={ opinionWinningRatio !== undefined ? "" : "text-transparent"}>{ opinionWinningRatio !== undefined ? Math.round(opinionWinningRatio * 100) + "%" : "n/a" } </div>
          </div>
        </li>
        <li className="w-full">
          <div className={"inline-block w-full p-4 bg-white rounded-r-lg focus:ring-2 focus:ring-blue-300 focus:outline-none dark:bg-gray-800 " + (categorizationWinnerSymbol !== undefined ? "hover:cursor-pointer hover:text-gray-700 hover:bg-gray-50 dark:hover:text-white dark:hover:bg-gray-700" : "")}>
          <div>{ categorizationWinnerSymbol !== undefined ? categorizationWinnerSymbol : "." }</div>
            <div className={ categorizationWinningRatio !== undefined ? "" : "text-transparent"}>{ categorizationWinningRatio !== undefined ? Math.round(categorizationWinningRatio * 100) + "%" : "n/a" } </div>
          </div>
        </li>
      </ul>
    </div>
	);
};

export default Aggregates;
