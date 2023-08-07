import StatusComponent         from "./Status";
import { Sub }                 from "../ActorContext";
import { StatusData }          from "./../../declarations/godwin_sub/godwin_sub.did";

import { useEffect, useState } from "react";
import { fromNullable }        from "@dfinity/utils";

type Props = {
  sub: Sub
  questionId: bigint;
  currentStatusData: StatusData;
};

const StatusHistoryComponent = ({sub, questionId, currentStatusData}: Props) => {

  const [statusHistory,  setStatusHistory]  = useState<StatusData[]>([currentStatusData]);
  const [historyVisible, setHistoryVisible] = useState<boolean     >(false              );

  const queryStatusHistory = async () => {
    if (statusHistory.length === 1) {
      const history = await sub.actor.getStatusHistory(questionId);
      if (history['ok'] !== undefined) {
        setStatusHistory(history['ok']);
      } else {
        throw new Error("Error getting status history: " + history['err']);
      }
    }
  }

  const toggleHistory = (toggle: boolean) => {
    if (fromNullable(currentStatusData.previous_status) !== undefined){
      setHistoryVisible(toggle);
    }
  };

  useEffect(() => {
    if (historyVisible) {
      queryStatusHistory();
    }
  }, [historyVisible]);

	return (
    <div className="text-gray-500 dark:border-gray-700 dark:text-gray-400">
      <ol>
      {
        statusHistory.slice(0).reverse().map((status_data, index) => {
          return (
            <li key={index.toString()}>
              {
                index === 0 || historyVisible ?
                <StatusComponent
                  sub={sub}
                  questionId={questionId}
                  statusData={status_data}
                  isToggledHistory={historyVisible}
                  toggleHistory={(toggle: boolean) => {toggleHistory(toggle)}}
                  isHistory={index !== 0}
                  showBorder={index !== 0 ? (index < statusHistory.length - 1) : (fromNullable(currentStatusData.previous_status) !== undefined) }
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
