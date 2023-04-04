import { Question, StatusInfo, Status, Time, Category, CategoryInfo, _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";
import { ActorSubclass } from "@dfinity/agent";
import VoteInterest from "./votes/Interest";
import VoteOpinion from "./votes/Opinion";
import VoteCategorization from "./votes/Categorization";

import StatusHistoryComponent from "./StatusHistory";

import { useEffect, useState } from "react";
import Aggregates from "./votes/Aggregates";
import { StatusEnum, statusToEnum } from "../utils";

type Props = {
	actor: ActorSubclass<_SERVICE>,
	categories: Map<Category, CategoryInfo>,
  questionId: bigint
};

function toMap(history_array: Array<[Status, Array<Time>]>) : Map<StatusEnum, Array<Time>> {
	let historyMap = new Map<StatusEnum, Array<Time>>();
  for (let [status, dates] of history_array) {
		historyMap.set(statusToEnum(status), dates);
  }
  return historyMap;
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
	const [statusHistoryArray, setStatusHistoryArray] = useState<StatusInfo[]>([]);
	const [statusHistoryMap, setStatusHistoryMap] = useState<Map<StatusEnum, Array<Time>>>();

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
			setStatusHistoryMap(toMap(history['ok']));
    };
  };

	useEffect(() => {
		getQuestion();
		getStatusInfo();
		fetchStatusHistory();
  }, []);

	const show = true;

	return (
		<div>
			{
				question === undefined || statusInfo === undefined ? <div>{Number(questionId)}</div> :
				<div className="flex flex-row bg-white dark:bg-gray-800 mb-2 text-gray-900 dark:text-white border-slate-700 border hover:dark:border-slate-400">
					<div className="flex flex-col py-1 px-10 justify-start w-full space-y-2">
						<div className="justify-start text-lg font-normal">
							{ question === undefined ? "n/a" : question.text }
						</div>
						<div className="flex items-center">
							<StatusHistoryComponent statusInfo={statusInfo} statusHistory={statusHistoryArray}/>
						</div>
						<div>
						{
							statusInfo.status['CLOSED'] !== undefined || statusInfo.status['REJECTED'] !== undefined ?
								<Aggregates actor={actor} categories={categories} questionId={questionId} statusHistory={statusHistoryMap}></Aggregates> :
								<></>
						}
						</div>
					</div>
					{
						statusInfo.status['CANDIDATE'] !== undefined ?
							<div className="flex items-center w-1/3 bg-white-100 dark:bg-gray-900">
								<VoteInterest actor={actor} questionId={question.id}/>
							</div> :
						statusInfo.status['OPEN'] !== undefined ?
							<div className="flex items-center w-1/3 bg-white-100 dark:bg-gray-900">
								<div className="flex flex-col justify-start">
									<VoteOpinion actor={actor} questionId={question.id}/>
									<VoteCategorization actor={actor} categories={categories} questionId={question.id}/>
								</div>
							</div> :
							<></>
					}
				</div>
			}
		</div>
	);
};

export default QuestionBody;
