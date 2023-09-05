import UserName                                   from "./UserName";
import Spinner                                    from "../Spinner";
import CopyIcon                                   from "../icons/CopyIcon";
import SvgButton                                  from "../base/SvgButton"
import LogoutIcon                                 from "../icons/LogoutIcon";
import { getEncodedAccount }                      from "../../utils/LedgerUtils";
import { airdropErrorToString }                   from "../../utils";
import { ActorContext }                           from "../../ActorContext"
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

const UserInfo = ({ principal } : UserInfoProps) => {

  const {isAuthenticated, authClient, master, airdrop, logout, refreshBalance} = useContext(ActorContext);

  const [isLoggedUser,         setIsLoggedUser        ] = useState<boolean>              (false                );
  const [isSelfAirdropAllowed, setIsSelfAirdropAllowed] = useState<boolean>              (false                );
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
      let account = await master.getUserAccount(principal);
      setAccount(account);
    }
  }

  const refreshSelfAirdropAllowed = async () => {
    setIsSelfAirdropAllowed(await airdrop.isSelfAirdropAllowed());
  }

  const claimAirdrop = () => {
    // @todo: temporary airdrop
    setError(undefined);
    setState(SubmittingState.SUBMITTING);
    airdrop.airdropSelf().then((result) => {
      if (result['ok'] !== undefined) {
        setState(SubmittingState.SUCCESS);
        refreshBalance();
      } else if (result['err'] !== undefined) {
        setState(SubmittingState.ERROR);
        setError(airdropErrorToString(result['err']));
      }
    });
  }

  useEffect(() => {
    refreshSelfAirdropAllowed();
  }, []);

  useEffect(() => {
		refreshLoggedUser();
  }, [isAuthenticated]);

  useEffect(() => {
    refreshAccount();
  }, [principal]);

	return (
    <div className="grid grid-cols-5 border-b dark:border-gray-700">
      <div className="col-start-2 col-span-3 flex flex-row justify-center dark:fill-white">
        <Link className="flex w-32 h-32 icon-svg" to={"/user/" + principal.toText()}>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M232.001 802.923q59.923-38.461 118.922-58.961 59-20.5 129.077-20.5t129.384 20.5q59.308 20.5 119.231 58.961 43.615-50.538 64.807-106.692Q814.615 640.077 814.615 576q0-141.538-96.538-238.077Q621.538 241.385 480 241.385t-238.077 96.538Q145.385 434.462 145.385 576q0 64.077 21.5 120.231 21.5 56.154 65.116 106.692Zm247.813-204.231q-53.968 0-90.775-36.994-36.808-36.993-36.808-90.961 0-53.967 36.994-90.775 36.993-36.807 90.961-36.807 53.968 0 90.775 36.993 36.808 36.994 36.808 90.961 0 53.968-36.994 90.775-36.993 36.808-90.961 36.808Zm-.219 357.307q-78.915 0-148.39-29.77-69.475-29.769-120.878-81.576-51.403-51.808-80.864-120.802-29.462-68.994-29.462-148.351 0-78.972 29.77-148.159 29.769-69.186 81.576-120.494 51.808-51.307 120.802-81.076 68.994-29.77 148.351-29.77 78.972 0 148.159 29.77 69.186 29.769 120.494 81.076 51.307 51.308 81.076 120.654 29.77 69.345 29.77 148.233 0 79.272-29.77 148.192-29.769 68.919-81.076 120.727-51.308 51.807-120.783 81.576-69.474 29.77-148.775 29.77Z"/></svg>
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
            {
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
            }
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
