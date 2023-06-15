import StatusComponent                                  from "./Status";

import { StatusInfo, _SERVICE, Category, CategoryInfo } from "./../../declarations/godwin_backend/godwin_backend.did";

import { useState }                                     from "react";
import { ActorSubclass }                                from "@dfinity/agent";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  questionId: bigint;
  categories: Map<Category, CategoryInfo>
  iteration: bigint,
  statusHistory: StatusInfo[]
};

const StatusHistoryComponent = ({actor, questionId, categories, iteration, statusHistory}: Props) => {

  const [historyVisible, setHistoryVisible] = useState<boolean>(false);

	return (
    <div className="text-gray-500 dark:border-gray-700 dark:text-gray-400">
      <ol>
      {
        statusHistory.slice(0).reverse().map((status, index) => {
          return (
            <li key={index.toString()}>
              {
                index === 0 || historyVisible ?
                <StatusComponent 
                  actor={actor}
                  questionId={questionId}
                  categories={categories}
                  status={status.status}
                  onStatusClicked={(e: React.MouseEvent<HTMLDivElement, MouseEvent>) => { if (index === 0 && statusHistory.length > 1) setHistoryVisible(!historyVisible) }}
                  date={status.date}
                  isHistory={index !== 0}
                  iteration={iteration}
                  showBorder={index !== 0 ? (index < statusHistory.length - 1) : (statusHistory.length > 1) }
                  borderDashed={index !== 0 ? false : !historyVisible}>
                </StatusComponent> :
                <></>
              }
            </li>
          )})
      }
		  </ol>
    </div>
	);
};

export default StatusHistoryComponent;
