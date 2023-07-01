import StatusComponent from "./Status";
import { Sub }         from "../ActorContext";
import { StatusInfo }  from "./../../declarations/godwin_sub/godwin_sub.did";

import { useState }    from "react";

type Props = {
  sub: Sub
  questionId: bigint;
  statusHistory: StatusInfo[]
};

const StatusHistoryComponent = ({sub, questionId, statusHistory}: Props) => {

  const [historyVisible, setHistoryVisible] = useState<boolean>(false);

  const toggleHistory = (toggle: boolean) => {
    if (statusHistory.length > 1) { setHistoryVisible(toggle); };
  };

	return (
    <div className="text-gray-500 dark:border-gray-700 dark:text-gray-400">
      <ol>
      {
        statusHistory.slice(0).reverse().map((statusInfo, index) => {
          return (
            <li key={index.toString()}>
              {
                index === 0 || historyVisible ?
                <StatusComponent 
                  sub={sub}
                  questionId={questionId}
                  statusInfo={statusInfo}
                  previousStatusInfo={statusHistory.length - index - 2 >= 0 ? statusHistory[statusHistory.length - index - 2] : undefined}
                  isToggledHistory={historyVisible}
                  toggleHistory={(toggle: boolean) => {toggleHistory(toggle)}}
                  isHistory={index !== 0}
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
