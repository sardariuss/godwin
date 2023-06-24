import SvgButton                           from "../base/SvgButton"
import EditIcon                            from "../icons/EditIcon";
import SaveIcon                            from "../icons/SaveIcon";
import CONSTANTS                           from "../../Constants";
import { ActorContext }                    from "../../ActorContext"
import { SetUserNameError }                from "../../../declarations/godwin_master/godwin_master.did";

import { Tooltip }                         from "@mui/material";
import ErrorOutlineIcon                    from '@mui/icons-material/ErrorOutline';

import { useEffect, useState, useContext } from "react";

import { Principal }                       from "@dfinity/principal";
import { fromNullable }                    from "@dfinity/utils";


enum EditingState {
  EDITING,
  SAVING,
  ERROR,
  SAVED
};

type UserNameProps = {
  principal: Principal | undefined,
  isLoggedUser: boolean,
};

const UserName = ({principal, isLoggedUser} : UserNameProps) => {

  const {master, refreshLoggedUserName} = useContext(ActorContext);

  const [userName,          setUserName    ] = useState<string | undefined>   (""                );
  const [editingName,       setEditingName ] = useState<string>               (""                );
  const [editState,         setEditState   ] = useState<EditingState>         (EditingState.SAVED);
  const [errorMessage,      setErrorMessage] = useState<string>               (""                );

  const refreshUserName = async () => {
    if (principal !== undefined && !principal.isAnonymous()) {
      let user_name = fromNullable(await master.getUserName(principal));
      setUserName(user_name);
    }
  };

  const refreshEditingName = async () => {
    setEditingName(userName ?? "");
  }

  const saveUserName = () => {
    setEditState(EditingState.SAVING);
    master.setUserName(editingName).then((result) => {
      if (result['ok'] !== undefined) {
        setEditState(EditingState.SAVED);
        setUserName(editingName);
        refreshLoggedUserName();
      } else if (result['err'] !== undefined){
        setErrorMessage(setUserNameErrorToString(result['err']));
        setEditState(EditingState.ERROR);
      } else {
        throw new Error('Invalid SetUserNameResult');
      }
    });
  };

  const setUserNameErrorToString = (error: SetUserNameError) : string => {
    if (error['AnonymousNotAllowed']!== undefined) return 'AnonymousNotAllowed';
    if (error['NameTooShort']!== undefined) return 'NameTooShort: (min_length = ' + Number(error['NameTooShort']['min_length']).toString() + ')';
    if (error['NameTooLong']!== undefined) return 'NameTooLong: (max_length = ' + Number(error['NameTooLong']['max_length']).toString() + ')';
    if (error['NameAlreadyTaken']!== undefined) return 'NameAlreadyTaken';
    throw new Error('Invalid SetUserNameError');
  }

  useEffect(() => {
    refreshUserName();
  }, [principal]);

  useEffect(() => {
		refreshEditingName();
  }, [userName]);

	return (
    <div className="flex flex-row gap-x-1 items-center">
      {
        editState !== EditingState.SAVED ?
          <input type="text" 
            className={`appearance-none bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-1 -ml-1 
              dark:bg-slate-900 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white focus:border-blue-500 dark:focus:border-blue-500
              ${editState === EditingState.SAVING ? "animate-pulse" : ""}`}
            disabled={ editState === EditingState.SAVING }
            defaultValue={ userName !== undefined ? userName : "" } 
            onChange={(e) => setEditingName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') { saveUserName() } 
              else if (e.key === 'Escape') { setEditState(EditingState.SAVED); } 
              else { setEditState(EditingState.EDITING); } } }
            autoFocus={true}
          /> :
          <div className="break-words">
            { userName !== undefined ? userName : CONSTANTS.USER_NAME.DEFAULT }
          </div>
      }
      {
        !isLoggedUser ? 
          <></> : 
        editState === EditingState.SAVED ? 
          <div className="w-5 h-5">
            <SvgButton onClick={(e) => {setEditState(EditingState.EDITING)}}>
              <EditIcon/>
            </SvgButton>
          </div> :
        editState === EditingState.EDITING || editState === EditingState.SAVING ?
          <div className="w-7 h-7">
            <SvgButton onClick={(e) => {saveUserName()}} disabled={ editState === EditingState.SAVING }>
              <SaveIcon/>
            </SvgButton>
          </div> :
        editState === EditingState.ERROR ?
          <div className="pl-1">
            <Tooltip title={errorMessage} arrow>
              <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
            </Tooltip>
          </div>  :
          <></>
      }
    </div>
	);
};

export default UserName;
