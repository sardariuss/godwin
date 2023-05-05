import { StatusInfo, _SERVICE, Category, CategoryInfo } from "./../../declarations/godwin_backend/godwin_backend.did";

import StatusComponent from "./Status";

import { useState } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  questionId: bigint;
  categories: Map<Category, CategoryInfo>
  statusInfo: StatusInfo,
  statusHistory: StatusInfo[]
};

const StatusHistoryComponent = ({actor, questionId, categories, statusInfo, statusHistory}: Props) => {

  const [historyVisible, setHistoryVisible] = useState<boolean>(false);

	return (
    <div className="text-gray-500 dark:border-gray-700 dark:text-gray-400">
      {
        statusInfo !== undefined ? (
          <div className={statusHistory.length > 0 ? "hover:cursor-pointer" : ""} onClick={(e) => { if (statusHistory.length > 0) setHistoryVisible(!historyVisible)}}>
            <StatusComponent 
              actor={actor}
              questionId={questionId}
              categories={categories}
              status={statusInfo.status}
              date={statusInfo.date}
              isHistory={false}
              iteration={statusInfo.iteration}
              showBorder={statusHistory.length > 0}
              borderDashed={!historyVisible}>
            </StatusComponent>
          </div>
        ) : (
          <></>
        )
      }
      <ol>
      {
        true ? (
          statusHistory.map((status, index) => {
            return (
              <li key={index.toString()}>
                <StatusComponent 
                  actor={actor}
                  questionId={questionId}
                  categories={categories}
                  status={status.status}
                  date={status.date}
                  isHistory={true}
                  iteration={status.iteration}
                  showBorder={index < (statusHistory.length - 1)}
                  borderDashed={false}>
                </StatusComponent>
              </li>
            )})
        ) : (
          <></>
        )
      }
		  </ol>
    </div>
	);
};

export default StatusHistoryComponent;
