import SingleCursorVote from "./base/SingleCursorVote";
import StatusHistoryComponent from "./StatusHistory";
import OpenVotes from "./votes/OpenVotes";
import { StatusEnum, statusToEnum } from "../utils";
import CONSTANTS from "../Constants";

import { Question, StatusInfo, Status, Time, Category, CategoryInfo, _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { useEffect, useState } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
	actor: ActorSubclass<_SERVICE>,
	categories: Map<Category, CategoryInfo>,
  questionId: bigint
};

function toArray(history_array: Array<[Status, Array<Time>]>) : StatusInfo[] {
  let history: StatusInfo[] = [];
  for (let [status, dates] of history_array) {
    let iteration = 0;
    for (let date of dates) {
      history.push({status: status, iteration: BigInt(iteration), date: date});
      iteration++;
    }
  }
  return history.sort((a, b) => Number(b.date - a.date));
};

const QuestionBody = ({actor, categories, questionId}: Props) => {

	const [question, setQuestion] = useState<Question | undefined>(undefined);
	const [statusInfo, setStatusInfo] = useState<StatusInfo | undefined>(undefined);
	const [showHistory, setShowHistory] = useState<boolean>(false);
	const [statusHistoryArray, setStatusHistoryArray] = useState<StatusInfo[]>([]);

	const getQuestion = async () => {
		let question = await actor.getQuestion(questionId);
		setQuestion(question['ok']);
	};

	const getStatusInfo = async () => {
		let statusInfo = await actor.getStatusInfo(questionId);
		setStatusInfo(statusInfo['ok']);
	};

	const fetchStatusHistory = async () => {
    let history = await actor.getStatusHistory(questionId);
    if (history['ok'] !== undefined){
      setStatusHistoryArray(toArray(history['ok']));
    };
  };

	useEffect(() => {
		getQuestion();
		getStatusInfo();
		fetchStatusHistory();
  }, []);

	return (
		<div className="flex flex-col text-gray-900 dark:text-white border-b border-slate-700">
			{
				question !== undefined && statusInfo !== undefined ?
				<div className="flex flex-row">
					<div className="flex flex-col py-1 px-10 justify-start w-full space-y-2">
						<div className="justify-start text-lg font-normal">
							{ question === undefined ? "n/a" : question.text }
						</div>
						<div className="flex items-center w-full justify-center">
						{
							statusInfo.status['CANDIDATE'] !== undefined ?
								<div className="grid grid-cols-10">
									<div className="col-start-2 col-span-8 place-self-center">
										<SingleCursorVote 
											countdownDurationMs={5000} 
											polarizationInfo={CONSTANTS.INTEREST_INFO} 
											questionId={question.id} 
											allowUpdateBallot={false}
											putBallot={actor.putInterestBallot}
											getBallot={actor.getInterestBallot}
										/>
									</div>
								</div> :
							statusInfo.status['OPEN'] !== undefined ?
								<OpenVotes actor={actor} questionId={question.id} categories={categories}/> : <></>
						}
						</div>
						{
							showHistory ?
								<div className="border-y border-slate-700">
									<StatusHistoryComponent actor={actor} categories={categories} questionId={questionId} statusInfo={statusInfo} statusHistory={statusHistoryArray}/>
								</div> :
								<></>
						}
						<div className="flex flex-row grow justify-around items-center text-gray-400 dark:fill-gray-400">
							<div className="flex w-1/3 justify-center items-center">
								<div className="h-4 w-4 hover:cursor-pointer hover:dark:dark:fill-white" onClick={(e) => setShowHistory(!showHistory)}>
									<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M477 936q-149 0-253-105.5T120 575h60q0 125 86 213t211 88q127 0 215-89t88-216q0-124-89-209.5T477 276q-68 0-127.5 31T246 389h105v60H142V241h60v106q52-61 123.5-96T477 216q75 0 141 28t115.5 76.5Q783 369 811.5 434T840 574q0 75-28.5 141t-78 115Q684 879 618 907.5T477 936Zm128-197L451 587V373h60v189l137 134-43 43Z"/></svg>
								</div>
							</div>
							<div className="flex w-1/3 justify-center items-center">
								<div className=" h-4 w-4 hover:cursor-pointer hover:dark:dark:fill-white">
									<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M727 976q-47.5 0-80.75-33.346Q613 909.307 613 861.669q0-6.669 1.5-16.312T619 828L316 652q-15 17-37 27.5T234 690q-47.5 0-80.75-33.25T120 576q0-47.5 33.25-80.75T234 462q23 0 44 9t38 26l303-174q-3-7.071-4.5-15.911Q613 298.25 613 290q0-47.5 33.25-80.75T727 176q47.5 0 80.75 33.25T841 290q0 47.5-33.25 80.75T727 404q-23.354 0-44.677-7.5T646 372L343 540q2 8 3.5 18.5t1.5 17.741q0 7.242-1.5 15Q345 599 343 607l303 172q15-14 35-22.5t46-8.5q47.5 0 80.75 33.25T841 862q0 47.5-33.25 80.75T727 976Zm.035-632Q750 344 765.5 328.465q15.5-15.535 15.5-38.5T765.465 251.5q-15.535-15.5-38.5-15.5T688.5 251.535q-15.5 15.535-15.5 38.5t15.535 38.465q15.535 15.5 38.5 15.5Zm-493 286Q257 630 272.5 614.465q15.5-15.535 15.5-38.5T272.465 537.5q-15.535-15.5-38.5-15.5T195.5 537.535q-15.5 15.535-15.5 38.5t15.535 38.465q15.535 15.5 38.5 15.5Zm493 286Q750 916 765.5 900.465q15.5-15.535 15.5-38.5T765.465 823.5q-15.535-15.5-38.5-15.5T688.5 823.535q-15.5 15.535-15.5 38.5t15.535 38.465q15.535 15.5 38.5 15.5ZM727 290ZM234 576Zm493 286Z"/></svg>
								</div>
							</div>
							<div className="flex w-1/3 justify-center items-center">
								<div className="text-xs font-light">
									{ "#CLASSIC6Q" + questionId.toString() }
								</div>
							</div>
						</div>
					</div>
				</div> : <></>
			}
		</div>
	);
};

export default QuestionBody;
