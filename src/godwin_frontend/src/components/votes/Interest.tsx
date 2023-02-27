import { Interest, Ballot_1 } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../../ActorContext"

import { nsToStrDate } from "../../utils";

import { useContext, useEffect, useState } from "react";

type Props = {
  question_id: bigint;
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
const VoteInterest = ({question_id}: Props) => {

  const {actor, isAuthenticated} = useContext(ActorContext);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);
  const [voteBallot, setVoteBallot] = useState<InterestEnum | null>(null);

  const putBallot = async () => {
    if (voteBallot !== null) {
      let interest_vote = await actor.putInterestBallot(question_id, fromEnum(voteBallot));
      console.log(interest_vote);
      await getBallot();
    }
	}

  const getBallot = async () => {
    if (isAuthenticated){
      let interest_vote = await actor.getInterestBallot(question_id);
      if (interest_vote['ok'] !== undefined && interest_vote['ok'].length > 0) {
        console.log(interest_vote);
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
      {
        voteDate !== null ?
        ( voteBallot === InterestEnum.UP ? 
          <label className="grow-0 flex-0 items-center p-1 rounded-2xl text-2xl bg-gray-100 dark:bg-gray-700">
            🤓 {nsToStrDate(voteDate)}
          </label> : voteBallot === InterestEnum.DOWN ? 
          <label className="grow-0 flex-0 items-center p-1 rounded-2xl text-2xl bg-gray-100 dark:bg-gray-700">
            🤡 {nsToStrDate(voteDate)}
          </label> : voteBallot === InterestEnum.DUPLICATE ?
          <label className="grow-0 flex-0 items-center p-1 rounded-2xl text-2xl bg-gray-100 dark:bg-gray-700">
            👀 {nsToStrDate(voteDate)}
          </label> :
          <div>
            ballot is null
          </div>
        ) :
        <div>
          <ul className="flex flew-row w-full justify-center">
            <li>
              <input type="radio" onClick={() => setVoteBallot(InterestEnum.UP)} id={"interest-up" + question_id.toString() } name={"interest" + question_id.toString() } value="interest-up" className="hidden peer" required/>
              <label htmlFor={ "interest-up" + question_id.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer dark:hover:text-2xl peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
              🤓
              </label>
            </li>
            <li>
              <input type="radio" onClick={() => setVoteBallot(InterestEnum.DOWN)} id={"interest-down" + question_id.toString() } name={"interest" + question_id.toString() } value="interest-down" className="hidden peer"/>
              <label htmlFor={ "interest-down" + question_id.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer dark:hover:text-2xl peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
              🤡
              </label>
            </li>
            <li>
              <input type="radio" onClick={() => setVoteBallot(InterestEnum.DUPLICATE)} id={"duplicate" + question_id.toString() } name={"interest" + question_id.toString() } value="duplicate" className="hidden peer"/>
              <label htmlFor={ "duplicate" + question_id.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer dark:hover:text-2xl peer-checked:text-2xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
              👀
              </label>
            </li>
          </ul>
          <button type="button" disabled={!isAuthenticated || voteBallot === null} onClick={() => putBallot()} className="text-gray-900 text-center items-center bg-white hover:enabled:bg-gray-100 border border-gray-200 focus:ring-4 focus:outline-none focus:ring-gray-100 font-medium rounded-lg text-sm dark:focus:ring-gray-600 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:enabled:bg-gray-700 mr-2 mb-2">
            💰 Vote
          </button>
        </div>
      }
    </div>
	);
};

export default VoteInterest;
