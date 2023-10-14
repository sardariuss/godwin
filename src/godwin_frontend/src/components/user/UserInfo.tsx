import UserName                                   from "./UserName";
import Spinner                                    from "../Spinner";
import CopyIcon                                   from "../icons/CopyIcon";
import SvgButton                                  from "../base/SvgButton"
import LogoutIcon                                 from "../icons/LogoutIcon";
import { getEncodedAccount }                      from "../../utils/LedgerUtils";
import { ActorContext }                           from "../../ActorContext"
import CONSTANTS                                  from "../../Constants";
import { Account }                                from "../../../declarations/godwin_master/godwin_master.did";

import React, { useEffect, useState, useContext } from "react";
import { Link }                                   from "react-router-dom";
import { Tooltip }                                from "@mui/material";
import ErrorOutlineIcon                           from "@mui/icons-material/ErrorOutline";
import DoneIcon                                   from '@mui/icons-material/Done';
import { Principal }                              from "@dfinity/principal";

enum SubmittingState {
  STILL,
  SUBMITTING,
  SUCCESS,
  ERROR,
};

type UserInfoProps = {
  principal: Principal;
};

// @btc: create btc account from principal
const UserInfo = ({ principal } : UserInfoProps) => {

  const {isAuthenticated, authClient, master, logout} = useContext(ActorContext);

  const [isLoggedUser,         setIsLoggedUser        ] = useState<boolean>              (false                );
  const [account,              setAccount             ] = useState<Account | undefined>  (undefined            );
  const [state,                setState               ] = useState<SubmittingState>      (SubmittingState.STILL);
  const [error,                setError               ] = useState<string | undefined>   (undefined            );

	const refreshLoggedUser = async () => {
    setIsLoggedUser(authClient?.getIdentity().getPrincipal().compareTo(principal) === "eq");
  }

  const refreshAccount = async () => {
    if (principal === undefined) {
      setAccount(undefined);
    } else {
      let account = await master?.getUserAccount(principal);
      setAccount(account);
    }
  }

  useEffect(() => {
		refreshLoggedUser();
  }, [isAuthenticated]);

  useEffect(() => {
    refreshAccount();
  }, [principal, master]);

	return (
    <div className="grid grid-cols-5 border-b dark:border-gray-700">
      <div className="col-start-2 col-span-3 flex flex-col items-center dark:fill-white items-center">
        <Link className="flex text-6xl text-center" to={"/user/" + principal.toText()}>
          { CONSTANTS.USER.DEFAULT_AVATAR }
        </Link>
        <UserName principal={principal} isLoggedUser={isLoggedUser}/>
      </div>
      <div className="col-start-5 flex justify-end self-end">
        { 
          isLoggedUser ?
          <div className="mr-2 w-8 h-8">
            <SvgButton onClick={(e) => { logout(); }}>
              <LogoutIcon/>
            </SvgButton>
          </div> : 
          <></> 
        }
      </div>
    </div>
	);
};

export default UserInfo;
