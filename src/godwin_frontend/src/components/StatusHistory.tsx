import StatusComponent                from "./Status";
import { Sub }                        from "../ActorContext";
import { StatusData }                 from "./../../declarations/godwin_sub/godwin_sub.did";

import React, { useEffect, useState } from "react";
import { fromNullable }               from "@dfinity/utils";

type Props = {
  sub: Sub
  questionId: bigint;
  statusData: StatusData;
};

const StatusHistoryComponent = ({sub, questionId, statusData}: Props) => {

  const [statusHistory,   setStatusHistory  ] = useState<StatusData[]>([statusData]);
  const [historyVisible,  setHistoryVisible ] = useState<boolean>     (false       );

  const queryStatusHistory = async () => {
    const history = await sub.actor.getStatusHistory(questionId);
    if (history['ok'] !== undefined) {
      setStatusHistory(history['ok']);
    } else {
      throw new Error("Error getting status history: " + history['err']);
    }
  }

  const isOnlyStatus = (status: StatusData) => {
    return status.is_current && fromNullable(status.previous_status) === undefined;
  };

  const toggleHistory = (toggle: boolean) => {
    if (!isOnlyStatus(statusData)){
      setHistoryVisible(toggle);
    }
  };

  useEffect(() => {
    if (historyVisible) {
      queryStatusHistory();
    } else {
      setStatusHistory([statusData]);
    }
  }, [historyVisible]);

  // If the statusData changes, reset the history
  useEffect(() => {
    setStatusHistory([statusData]);
    setHistoryVisible(false);
  }, [statusData]);

	return (
    <div className="text-gray-500 dark:border-gray-700 dark:text-gray-400">
      <ol>
      {
        statusHistory.slice(0).reverse().map((status_data, index) => {
          return (
            <li key={index.toString()}>
              <StatusComponent
                sub={sub}
                statusData={status_data}
                canToggle={index === 0}
                isToggledHistory={historyVisible}
                toggleHistory={toggleHistory}
                showBorder={(fromNullable(status_data.previous_status) !== undefined) || (!historyVisible && !status_data.is_current)}
                borderDashed={!historyVisible}/>
            </li>
          )})
      }
      </ol>
    </div>
	);
};

export default StatusHistoryComponent;
