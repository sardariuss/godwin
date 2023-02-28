import { Interest } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../../ActorContext"

import { nsToStrDate } from "../../utils";

import { useContext, useEffect, useState } from "react";

type Props = {
  questionId: bigint;
};

enum InterestEnum {
  UP,
  DOWN,
  DUPLICATE
};

function fromEnum(interest_enum: InterestEnum) : Interest {
  switch(interest_enum) {
    case InterestEnum.UP:
      return {'UP' : null };
    case InterestEnum.DOWN:
      return {'DOWN' : null };
    case InterestEnum.DUPLICATE:
      throw new Error("InterestEnum.DUPLICATE is not implemented yet");
  }
};

function toEnum(interest: Interest) : InterestEnum {
  if (interest['UP'] !== undefined) {
    return InterestEnum.UP;
  } else if (interest['DOWN'] !== undefined) {
    return InterestEnum.DOWN;
  } else if (interest['DUPLICATE'] !== undefined) {
    return InterestEnum.DUPLICATE;
  } else {
    throw new Error("interest is not a valid Interest");
  }
}

// @todo: change the state of the buttons based on the interest for the logged user for this question
// @todo: putInterestBallot on click
const VoteInterest = ({questionId}: Props) => {

  const {actor, isAuthenticated} = useContext(ActorContext);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);
  const [voteBallot, setVoteBallot] = useState<InterestEnum | null>(null);

  const putBallot = async () => {
    if (voteBallot !== null) {
      let interest_vote = await actor.putInterestBallot(questionId, fromEnum(voteBallot));
      console.log(interest_vote);
      await getBallot();
    }
	}

  const getBallot = async () => {
    if (isAuthenticated){
      let interest_vote = await actor.getInterestBallot(questionId);
      if (interest_vote['ok'] !== undefined && interest_vote['ok'].length > 0) {
        setVoteBallot(toEnum(interest_vote['ok'][0].answer));
        setVoteDate(interest_vote['ok'][0].date);
      } else {
        setVoteBallot(null);
        setVoteDate(null);
      }
    }
  }

  useEffect(() => {
    getBallot();
  }, []);

  useEffect(() => {
    getBallot();
  }, [isAuthenticated]);

	return (
    <div className="flex flex-col gap-y-2 w-full justify-center">
      <div>
        <ul className="flex flew-row w-full justify-center">
          <li>
            <input type="radio" disabled={ voteDate !== null } checked={ voteBallot === InterestEnum.UP } onClick={() => setVoteBallot(InterestEnum.UP)} onChange={() => {}} id={"interest-up" + questionId.toString() } name={"interest" + questionId.toString() } value="interest-up" className="hidden peer" required/>
            {
              voteDate !== null ? 
                <label htmlFor={ "interest-up" + questionId.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl                               peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
                🤓
                </label>
               : 
                <label htmlFor={ "interest-up" + questionId.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer hover:text-2xl peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
                🤓
                </label>
            }
          </li>
          <li>
            <input type="radio" disabled={ voteDate !== null } checked={ voteBallot === InterestEnum.DOWN } onClick={() => setVoteBallot(InterestEnum.DOWN)} onChange={() => {}} id={"interest-down" + questionId.toString() } name={"interest" + questionId.toString() } value="interest-down" className="hidden peer"/>
            {
              voteDate !== null ? 
                <label htmlFor={ "interest-down" + questionId.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl                               peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
                🤡
                </label>
               : 
                <label htmlFor={ "interest-down" + questionId.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer hover:text-2xl peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
                🤡
                </label>
            }
          </li>
          <li>
            <input type="radio" disabled={ voteDate !== null } checked={ voteBallot === InterestEnum.DUPLICATE } onClick={() => setVoteBallot(InterestEnum.DUPLICATE)} onChange={() => {}} id={"duplicate" + questionId.toString() } name={"interest" + questionId.toString() } value="duplicate" className="hidden peer"/>
            {
              voteDate !== null ? 
                <label htmlFor={ "duplicate" + questionId.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl                               peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
                👀
                </label>
               : 
                <label htmlFor={ "duplicate" + questionId.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer hover:text-2xl peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
                👀
                </label>
            }
          </li>
        </ul>
        {
          voteDate !== null ?
          <div className="w-full p-2 items-center text-center text-xs font-extralight">{ "🗳️ " + nsToStrDate(voteDate) }</div> :
          <button type="button" disabled={!isAuthenticated || voteBallot === null} onClick={() => putBallot()} className="w-full text-gray-900 text-center items-center bg-white hover:enabled:bg-gray-100 border border-gray-200 focus:ring-4 focus:outline-none focus:ring-gray-100 font-medium rounded-lg text-sm dark:focus:ring-gray-600 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:enabled:bg-gray-700 mr-2 mb-2">
            💰 Vote
          </button>
        }
      </div>
    </div>
	);
};

export default VoteInterest;
