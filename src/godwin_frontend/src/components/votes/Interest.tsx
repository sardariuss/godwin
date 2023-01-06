import { _SERVICE} from "./../../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../../ActorContext"

import { useContext } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
  question_id: number;
};

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const VoteInterest = ({question_id}: Props) => {

	const {actor, logged_in} = useContext(ActorContext) as ActorContextValues;

	const upVote = async () => {
		console.log("upVote");
		let up_vote = await actor.setInterest(question_id, { 'UP' : null });
		console.log(up_vote);
	};

	const downVote = async () => {
		console.log("downVote");
		let down_vote = await actor.setInterest(question_id, { 'DOWN' : null });
		console.log(down_vote);
	};

	return (
    <ul className="flex flex-row items-center justify-evenly space-x-1">
      <li>
        <input type="radio" disabled={!logged_in} onClick={(e) => upVote()} id={"up-vote_" + question_id} name={"vote_" + question_id} value="up-vote" className="hidden peer" required/>
        <label htmlFor={"up-vote_" + question_id} className="inline-flex font-bold cursor-pointer justify-center items-center px-4 py-2 text-gray-500 bg-white rounded-lg dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-green-500 peer-checked:border-green-500 peer-checked:text-green-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">
          ⇧
        </label>
      </li>
      <li>
        <input type="radio" disabled={!logged_in} onChange={(e) => downVote()} id={"down-vote_" + question_id} name={"vote_" + question_id} value="down-vote" className="hidden peer"/>
        <label htmlFor={"down-vote_" + question_id} className="inline-flex font-bold cursor-pointer justify-center items-center px-5 py-2 text-gray-500 bg-white rounded-lg dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-red-500 peer-checked:border-red-500 peer-checked:text-red-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">
          ⇩
        </label>
      </li>
    </ul>
	);
};

export default VoteInterest;
