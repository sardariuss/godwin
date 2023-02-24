import { Appeal, Polarization, PolarizationArray, Question } from "./../../declarations/godwin_backend/godwin_backend.did";
import { ActorContext } from "../ActorContext"
import VoteInterest from "./votes/Interest";
import VoteOpinion from "./votes/Opinion";
import VoteCategorization from "./votes/Categorization";
import Aggregates from "./votes/Aggregates";

import { statusToString, nsToStrDate } from "../utils";

import { useEffect, useState, useContext } from "react";

type Props = {
  question_id: bigint,
	categories: string[]
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const QuestionBody = ({question_id, categories}: Props) => {

	const {actor} = useContext(ActorContext);
	const [question, setQuestion] = useState<Question | undefined>(undefined);
	const [interestAggregate, setInterestAggregate] = useState<Appeal | undefined>(undefined);
	const [opinionAggregate, setOpinionAggregate] = useState<Polarization | undefined>(undefined);
	const [categorizationAggregate, setCategorizationAggregate] = useState<PolarizationArray | undefined>(undefined);

	const getQuestion = async () => {
		let question = await actor.getQuestion(question_id);
		setQuestion(question['ok']);
	};

	// @todo: need to check status and handle case where history is empty
	const getInterestAggregate = async () => {
		let aggregate = await actor.getInterestAggregate(question_id, BigInt(0)); // @todo: hardcoded iteration
		setInterestAggregate(aggregate['ok']);
	};

	// @todo: need to check status and handle case where history is empty
	const getOpinionAggregate = async () => {
		let aggregate = await actor.getOpinionAggregate(question_id, BigInt(0)); // @todo: hardcoded iteration
		setOpinionAggregate(aggregate['ok']);
	};

	// @todo: need to check status and handle case where history is empty
	const getCategorizationAggregate = async () => {
		let aggregate = await actor.getCategorizationAggregate(question_id, BigInt(0)); // @todo: hardcoded iteration
		setCategorizationAggregate(aggregate['ok']);
	};

	useEffect(() => {
		getQuestion();
		getInterestAggregate();
		getOpinionAggregate();
		getCategorizationAggregate();
  }, []);

	const show = true;

	return (
		<div className="flex flex-row py-1 px-10 bg-white dark:bg-gray-800 mb-2 text-gray-900 dark:text-white hover:dark:border">
			<div className="flex flex-row w-1/3 gap-x-10 text-lg font-semibold">
				{ 
					question?.status_info.current.status['VOTING'] !== undefined ? (
						question?.status_info.current.status['VOTING']['INTEREST'] !== undefined ?
							<VoteInterest question_id={question.id}/> : 
						question?.status_info.current.status['VOTING']['OPINION'] !== undefined ?
							<VoteOpinion question_id={question.id}/> :
						question?.status_info.current.status['VOTING']['CATEGORIZATION'] !== undefined ?
							<VoteCategorization question_id={question.id} categories={categories}/> :
							<div>@todo impossible</div>
					) :
					question?.status_info.current.status['CLOSED'] !== undefined || question?.status_info.current.status['REJECTED'] !== undefined ?
						<Aggregates 
							interest_aggregate={interestAggregate}
							opinion_aggregate={opinionAggregate}
							categorization_aggregate={categorizationAggregate}
						/> : <div>@todo impossible</div>
				}
			</div>
			<div className="flex flex-row w-2/3 justify-start gap-x-10">
				<div className="flex flex-col justify-start gap-x-10 text-lg font-semibold">
					<div className="flex flex-row justify-start gap-x-10 text-lg font-normal">
						<div> { question === undefined ? "title" : question.title} </div>
					</div>
					<ol className="relative text-gray-500 border-l border-gray-200 dark:border-gray-700 dark:text-gray-400">
						<li className="mb-10 ml-6 text-gray-900 dark:text-white">
							<span className="absolute flex items-center justify-center w-8 h-8 bg-blue-200 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 dark:bg-blue-900">
								<svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5 text-blue-500 dark:text-blue-400" fill="currentColor" viewBox="0 96 960 960" width="48"><path d="m550 972-42-42 142-142-382-382-142 142-42-42 56-58-56-56 85-85-42-42 42-42 43 41 84-84 56 56 58-56 42 42-142 142 382 382 142-142 42 42-56 58 56 56-86 86 42 42-42 42-42-42-84 84-56-56-58 56Z"/></svg>
							</span>
							<h3 className="font-medium leading-tight">Candidate</h3>
							<div className="text-sm font-extralight">{ question === undefined ? "date" : nsToStrDate(question.date)}</div>
						</li>
						<li className="mb-10 ml-6">
							<span className="absolute flex items-center justify-center w-8 h-8 bg-gray-100 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 dark:bg-gray-700">
								<svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5 text-gray-500 dark:text-gray-400" fill="currentColor" viewBox="0 96 960 960" width="48"><path d="M180 976q-24 0-42-18t-18-42V718l135-149 43 43-118 129h600L669 615l43-43 128 146v198q0 24-18 42t-42 18H180Zm0-60h600V801H180v115Zm262-245L283 512q-19-19-17-42.5t20-41.5l212-212q16.934-16.56 41.967-17.28Q565 198 583 216l159 159q17 17 17.5 40.5T740 459L528 671q-17 17-42 18t-44-18Zm249-257L541 264 333 472l150 150 208-208ZM180 916V801v115Z"/></svg>
							</span>
							<ol className="flex items-center w-full space-x-1">
								<li className="flex items-center">
									<h3 className="font-medium leading-tight">Open</h3>
								</li>
								<li className="flex items-center">
									<div className="text-sm font-normal"></div>
								</li>
							</ol>
							<div className="text-sm font-extralight">{ question === undefined ? "date" : nsToStrDate(question.date)}</div>
							<ol className="flex items-center w-full space-y-5">
								<li className="text-sm font-light items-center justify-center whitespace-nowrap">
								🏅 152 points:
								</li>
								<ol className="flex w-full space-x-10">
									<li className="flex w-[70px] items-center justify-center overflow-visible text-white hover:z-0">
										<div className="text-xs font-extralight whitespace-nowrap">
											4312 🤓
										</div>
									</li>
									<li className="flex w-[80px] items-center justify-center overflow-visible text-white hover:z-0">
										<div className="text-xs font-extralight whitespace-nowrap">
											212 🤡
										</div>
									</li>
									<li className="flex w-[50px] items-center justify-center overflow-visible text-white hover:z-0">
										<div className="text-xs font-extralight whitespace-nowrap">
											321 👀
										</div>
									</li>
								</ol>
							</ol>
						</li>
						<li className="mb-10 ml-6">
							<span className="absolute flex items-center justify-center w-8 h-8 bg-gray-100 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 dark:bg-gray-700">
								<svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5 text-gray-500 dark:text-gray-400" fill="currentColor" viewBox="0 96 960 960" width="48"><path d="M431 922H180q-24 0-42-18t-18-42V280q0-24 15.5-42t26.5-18h202q7-35 34.5-57.5T462 140q36 0 63.5 22.5T560 220h202q24 0 42 18t18 42v203h-60V280H656v130H286V280H180v582h251v60Zm189-25L460 737l43-43 117 117 239-239 43 43-282 282ZM480 276q17 0 28.5-11.5T520 236q0-17-11.5-28.5T480 196q-17 0-28.5 11.5T440 236q0 17 11.5 28.5T480 276Z"/></svg>
							</span>
							<ol className="flex items-center w-full space-x-1">
								<li className="flex items-center">
									<h3 className="font-medium leading-tight">Closed</h3>
								</li>
								<li className="flex items-center">
									<div className="text-sm font-normal">· 🤷 indecisive</div>
								</li>
								<li className="flex items-center">
									<div className="text-sm font-normal">· 🧭 identity</div>
								</li>
							</ol>
							<div className="text-sm font-extralight">{ question === undefined ? "date" : nsToStrDate(question.date)}</div>
							<ol className="flex items-center w-full space-y-5">
								<li className="text-sm font-light whitespace-nowrap">
									Opinion:
								</li>
								<ol className="flex w-full justify-end">
									<li className="flex w-[70px] h-4 bg-google-red justify-center overflow-visible text-black/100 hover:z-0">
										<div className="text-xs font-extralight whitespace-nowrap">
											35% 👎
										</div>
									</li>
									<li className="flex w-[80px] h-4 bg-white justify-center overflow-visible text-black/100 hover:z-0">
										<div className="text-xs font-extralight whitespace-nowrap">
											40% 🤷
										</div>
									</li>
									<li className="flex w-[50px] h-4 bg-google-green justify-center overflow-visible text-black/100 hover:z-0">
										<div className="text-xs font-extralight whitespace-nowrap">
											25% 👍
										</div>
									</li>
								</ol>
							</ol>
						</li>
						<li className="mb-10 ml-6">
							<span className="absolute flex items-center justify-center w-8 h-8 bg-gray-100 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 dark:bg-gray-700">
								<svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5 text-gray-500 dark:text-gray-400" fill="currentColor" viewBox="0 96 960 960" width="48"><path d="M480 534q69 0 116.5-50.5T644 362V236H316v126q0 71 47.5 121.5T480 534ZM160 976v-60h96V789q0-70 36.5-128.5T394 576q-65-26-101.5-85T256 362V236h-96v-60h640v60h-96v126q0 70-36.5 129T566 576q65 26 101.5 84.5T704 789v127h96v60H160Z"/></svg>
							</span>
							<ol className="flex items-center w-full space-x-1">
							<li className="flex items-center">
									<h3 className="font-medium leading-tight">Timed out</h3>
								</li>
								<li className="flex items-center">
									<div className="text-sm font-normal">· 🏅 15 points</div>
								</li>
							</ol>
							<div className="text-sm font-extralight">{ question === undefined ? "date" : nsToStrDate(question.date)}</div>
						</li>
						<li className="ml-6">
							<span className="absolute flex items-center justify-center w-8 h-8 bg-gray-100 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 dark:bg-gray-700">
								<svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5 text-gray-500 dark:text-gray-400" fill="currentColor" viewBox="0 96 960 960" width="48"><path d="m249 849-42-42 231-231-231-231 42-42 231 231 231-231 42 42-231 231 231 231-42 42-231-231-231 231Z"/></svg>
							</span>
							<ol className="flex items-center w-full space-x-1">
								<li className="flex items-center">
									<h3 className="font-medium leading-tight">Rejected</h3>
								</li>
								<li className="flex items-center">
									<div className="text-sm font-normal">· 🏅 -13 points</div>
								</li>
							</ol>
							<div className="text-sm font-extralight">{ question === undefined ? "date" : nsToStrDate(question.date)}</div>
						</li>
					</ol>
				</div>
			</div>
		</div>
	);
};

export default QuestionBody;
