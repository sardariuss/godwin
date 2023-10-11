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

  const {isAuthenticated, authClient, master, logout, refreshBalance} = useContext(ActorContext);

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
      <div className="col-start-2 col-span-3 flex flex-row justify-center dark:fill-white items-center">
        <Link className="flex text-6xl text-center" to={"/user/" + principal.toText()}>
          { CONSTANTS.USER.DEFAULT_AVATAR }
        </Link>
        <div className="flex flex-col mt-1 justify-evenly">
          <UserName principal={principal} isLoggedUser={isLoggedUser}/>
          {
            account !== undefined ? 
            <div className="flex flex-row gap-x-1 items-center">
              <div>
                { "Account" }
              </div>
              <div className="w-5 h-5">
                <SvgButton onClick={(e) => navigator.clipboard.writeText(getEncodedAccount(account))} disabled={false} hidden={false}>
                  <CopyIcon/>
                </SvgButton>
              </div>
            </div> : <></>
          }
          <div className="flex flex-row items-center space-x-2">
            {/*
              isLoggedUser && isSelfAirdropAllowed ?
              <button type="button" onClick={(e) => claimAirdrop()} className="flex flex-col items-center button-blue w-24" disabled={state === SubmittingState.SUBMITTING}>
                {
                  state === SubmittingState.SUBMITTING ?
                  <div className="w-5 h-5">
                    <Spinner/>
                  </div> : 
                  <div className="text-white">
                    Airdrop
                  </div>
                }
              </button> : <></>
              */}
            <div className="flex flex-col w-6 min-w-6 items-center text-sm">
            {
              state === SubmittingState.ERROR ?
                <div className="w-full">
                  <Tooltip title={error} arrow>
                    <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
                  </Tooltip>
                </div> : 
              state === SubmittingState.SUCCESS ?
                <div className="w-full">
                  <DoneIcon color="success"/>
                </div> :
                <></>
            }
            </div>
          </div>
        </div>
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
