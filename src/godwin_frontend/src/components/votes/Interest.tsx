import { ActorContext } from "../../ActorContext"

import { useContext } from "react";

type Props = {
  question_id: bigint;
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const VoteInterest = ({question_id}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);

	const upVote = async () => {
    // 🤔 🧠 
		console.log("upVote");
		let up_vote = await actor.putInterestBallot(question_id, { 'UP' : null } );
		console.log(up_vote);
	};

	const downVote = async () => {
		console.log("downVote");
    let down_vote = await actor.putInterestBallot(question_id, { 'DOWN' : null });
		console.log(down_vote);
	};

  const duplicateVote = async () => {
		console.log("duplicateVote");
    // @todo
	};

	return (
    <ul className="flex flex-row items-center justify-evenly space-x-1 rounded-lg">
      <li>
        <input type="radio" disabled={!isAuthenticated} onClick={(e) => upVote()} id={"up-vote_" + question_id} name={"vote_" + question_id} value="up-vote" className="hidden peer" required/>
        <label htmlFor={"up-vote_" + question_id} className="inline-flex text-xl font-bold cursor-pointer justify-center items-center px-2 py-2 rounded-lg dark:hover:bg-gray-700 dark:hover:text-2xl">
         🤓
        </label>
      </li>
      <li>
        <input type="radio" disabled={!isAuthenticated} onChange={(e) => downVote()} id={"down-vote_" + question_id} name={"vote_" + question_id} value="down-vote" className="hidden peer"/>
        <label htmlFor={"down-vote_" + question_id} className="inline-flex text-xl font-bold cursor-pointer justify-center items-center px-2 py-2 text-gray-500 rounded-lg dark:hover:bg-gray-700 dark:hover:text-2xl">
         🤡
        </label>
      </li>
      <li>
        <input type="radio" disabled={!isAuthenticated} onChange={(e) => duplicateVote()} id={"duplicate-vote_" + question_id} name={"vote_" + question_id} value="duplicate-vote" className="hidden peer"/>
        <label htmlFor={"duplicate-vote_" + question_id} className="inline-flex text-xl font-bold cursor-pointer justify-center items-center px-2 py-2 text-gray-500 rounded-lg dark:hover:bg-gray-700 dark:hover:text-2xl">
         👀
        </label>
      </li>
    </ul>
	);
};

export default VoteInterest;
