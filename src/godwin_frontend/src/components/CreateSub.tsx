import TextInput                                                 from "./TextInput";
import DurationInput                                             from "./DurationInput";
import NumberInput                                               from "./NumberInput";
import CreateSubButton                                           from "./CreateSubButton";
import { ColorPickerPopover }                                    from "./ColorPickerPopover";
import { EmojiPickerPopover }                                    from "./EmojiPickerPopover";
import Spinner                                                   from "./Spinner";
import Balance                                                   from "./base/Balance";
import SvgButton                                                 from "./base/SvgButton";
import CONSTANTS                                                 from "../Constants";
import { createSubResultToError, createSubGodwinErrorToString }  from "../utils";
import { ActorContext }                                          from "../ActorContext"
import { Category, CategoryInfo, SchedulerParameters, 
  ConvictionsParameters, SelectionParameters }                   from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect, useContext }                from "react";
import { Tooltip }                                               from "@mui/material";
import ErrorOutlineIcon                                          from "@mui/icons-material/ErrorOutline";
import { useNavigate }                                           from "react-router-dom";

const createDimension = () : [Category, CategoryInfo] => { 
  return [
    "",
    {
      left:  {name: "", symbol: CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.CATEGORY.EMOJI, color: CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.CATEGORY.COLOR},
      right: {name: "", symbol: CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.CATEGORY.EMOJI, color: CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.CATEGORY.COLOR}
    }
  ];
}

const CreateSub = () => {

  const { master, refreshBalance, addSub } = useContext(ActorContext);

  const [name,                  setName                 ] = useState<string>                    (""                                                         );
  const [identifier,            setIdentifier           ] = useState<string>                    (""                                                         );
  const [categories,            setCategories           ] = useState<[Category, CategoryInfo][]>([createDimension()]                                        );
  const [selectionParameters,   setSelectionParameters  ] = useState<SelectionParameters>       (CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.SELECTION_PARAMETERS  );
  const [schedulerParameters,   setSchedulerParameters  ] = useState<SchedulerParameters>       (CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.SCHEDULER_PARAMETERS  );
  const [convictionsParameters, setConvictionsParameters] = useState<ConvictionsParameters>     (CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.CONVICTIONS_PARAMETERS);
  const [characterLimit,        setCharacterLimit       ] = useState<bigint>                    (CONSTANTS.NEW_SUB_DEFAULT_PARAMETERS.CHARACTER_LIMIT       );
  
  const [showGeneral,           setShowGeneral          ] = useState<boolean>                   (false                                                      );
  const [showDimensions,        setShowDimensions       ] = useState<boolean>                   (false                                                      );
  const [showSelectionParams,   setShowSelectionParams  ] = useState<boolean>                   (false                                                      );
  const [showSchedulerParams,   setShowSchedulerParams  ] = useState<boolean>                   (false                                                      );
  const [showConvictionsParams, setShowConvictionsParams] = useState<boolean>                   (false                                                      );

  const [submitting,            setSubmitting           ] = useState<boolean>                   (false                                                      );
  const [error,                 setError                ] = useState<string | undefined>        (undefined                                                  );
  const [subCreationPrice,      setSubCreationPrice     ] = useState<bigint | undefined>        (undefined                                                  );

  const navigate = useNavigate();

  const refreshSubCreationPrice = async () => {
    
    master.getSubCreationPriceE8s().then((price) => {
      setSubCreationPrice(price);
    }).catch((err) => {
      console.error(err);
      setSubCreationPrice(undefined);
    });
  }

  const updateCategory = (index: number, to_update: [Category, CategoryInfo]) => {
    setCategories( old => { 
      return old.map(([category, info], i) => {
        if (i === index) { return to_update;          } 
        else             { return [category, info];   }
      });
    });
  }

  const createSubGodwin = async () => {
    setError(undefined);
    setSubmitting(true);
    
    master.createSubGodwin(identifier, { 
      name,
      categories,
      selection: selectionParameters,
      scheduler: schedulerParameters,
      convictions: convictionsParameters,
      character_limit: characterLimit
    }).then((result) => {
      console.log(result);
      if (result['ok'] !== undefined){
        addSub(result['ok'], identifier).then(() => {
          navigate("/g/" + identifier);
        }).catch((err) => {
          setError(err.toString());
        });
      } else if (result['err'] !== undefined){
        setError(createSubGodwinErrorToString(result['err']));
      }
    }).catch((err) => {
      setError(err.toString());
    }).finally(() => {
      setSubmitting(false);
      refreshBalance();
    });
  }

  const validateText = async(input: string) : Promise<string | undefined> => {
    return Promise.resolve(input.length === 0 ? "Text is empty" : undefined);
  }

  useEffect(() => {
    console.log("refreshing sub creation price");
    refreshSubCreationPrice();
  }, []);

  return (
    <div className="flex flex-col items-center justify-center content-center">
      <CreateSubButton show={showGeneral} setShow={setShowGeneral} label={"General"}>
        <div className="flex flex-col justify-evenly w-full items-center place-items-center gap-y-3 pb-2">
          <TextInput 
            label="Name"
            id={"name"}
            input={name}
            onInputChange={setName}
            validate={(input) => { return master.validateSubName(input).then(createSubResultToError) }}
          />
          <TextInput 
            label="Identitifer" 
            id={"identifier"} 
            input={identifier}  
            onInputChange={setIdentifier} 
            validate={(input) => { return master.validateSubIdentifier(input).then(createSubResultToError) }}
          />
          <NumberInput
            label="Question character limit"
            id={"character_limit"}
            input={Number(characterLimit)}
            onInputChange={(input: number) => { setCharacterLimit(BigInt(input)); } }
            validate={(input: number) => { return master.validateCharacterLimit(BigInt(input)).then(createSubResultToError) }}
          />
        </div>
      </CreateSubButton>
      <CreateSubButton show={showDimensions} setShow={setShowDimensions} label={"Dimensions"}>
        <ol className="flex flex-col divide-y divide-gray-300 dark:divide-gray-300 xl:w-1/2 lg:w-2/3 md:w-full sm:w-full">
          {
            categories.map(([category, info], index) => (
            <li className="pt-2 grid col-span-12 pb-2 grid-cols-12 text-gray-900 dark:text-white items-center place-items-center gap-x-2" key={index.toString()}>
              <div className="col-span-3 justify-self-start place-self-start">
                <TextInput 
                  label={ "Dimension " + (index + 1).toString()}
                  id={"category" + index.toString()} input={category }
                  onInputChange={(input) => { category = input; updateCategory(index, [category, info]); }}
                  validate={validateText}
                />
              </div>
              <div className="col-span-4 flex flex-row gap-x-2 items-center">
                <TextInput 
                  label="Left axis"
                  id={"lname" + index.toString()} input={info.left.name}
                  onInputChange={(input) => { info.left.name = input; updateCategory(index, [category, info]); }} 
                  dir={"rtl"}
                  validate={validateText}
                />
                <ColorPickerPopover color={info.left.color} onChange={(input) => { info.left.color  = input; updateCategory(index, [category, info]); }} />
                <EmojiPickerPopover emoji={info.left.symbol} onChange={(input) => { info.left.symbol = input; updateCategory(index, [category, info]); }}/>
              </div>
              <div className="col-span-4 flex flex-row gap-x-2 items-center">
                <EmojiPickerPopover emoji={info.right.symbol} onChange={(input) => { info.right.symbol = input; updateCategory(index, [category, info]); }}/>
                <ColorPickerPopover color={info.right.color } onChange={(input) => { info.right.color  = input; updateCategory(index, [category, info]); }}/>
                <TextInput 
                  label="Right axis"
                  id={"rname" + index.toString()}
                  input={info.right.name}
                  onInputChange={(input) => { info.right.name = input; updateCategory(index, [category, info]); }}
                  validate={validateText} 
                />
              </div>
              <div className="col-span-1 justify-self-end grid grid-cols-2 gap-x-2 items-center">
                <div className={`w-5 h-5`}>
                  <SvgButton onClick={() => { setCategories(categories.filter((_, cat_index) => index !== cat_index)); }} disabled={categories.length === 1} hidden={false}>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M261-120q-24 0-42-18t-18-42v-570h-41v-60h188v-30h264v30h188v60h-41v570q0 24-18 42t-42 18H261Zm106-146h60v-399h-60v399Zm166 0h60v-399h-60v399Z"/></svg>
                  </SvgButton>
                </div>
                <div className={`w-5 h-5 ${index !== (categories.length - 1) ? "hidden" : ""}`}>
                  <SvgButton onClick={() => setCategories([...categories, createDimension()])} disabled={categories.length >= CONSTANTS.MAX_NUM_CATEGORIES} hidden={false}>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M453-280h60v-166h167v-60H513v-174h-60v174H280v60h173v166Zm27.266 200q-82.734 0-155.5-31.5t-127.266-86q-54.5-54.5-86-127.341Q80-397.681 80-480.5q0-82.819 31.5-155.659Q143-709 197.5-763t127.341-85.5Q397.681-880 480.5-880q82.819 0 155.659 31.5Q709-817 763-763t85.5 127Q880-563 880-480.266q0 82.734-31.5 155.5T763-197.684q-54 54.316-127 86Q563-80 480.266-80Z"/></svg>
                  </SvgButton>
                </div>
              </div>
            </li>
            ))}
        </ol>
      </CreateSubButton>
      <CreateSubButton show={showSelectionParams} setShow={setShowSelectionParams} label={"Selection parameters"}>
        <div className="flex flex-col w-full gap-y-6 mb-3 items-center">
          <DurationInput id={"selection_period"} label={"Question selection period"} input={selectionParameters.selection_period } 
            onInputChange={(input)=> { setSelectionParameters(params => { params.selection_period = input; return params; } )}}
            validate={(input) => { return master.validateSchedulerDuration(input).then(createSubResultToError) }}/>
          <NumberInput
            label="Minimum interest score"
            id={"minimum_interest_score"}
            input={selectionParameters.minimum_score}
            onInputChange={(input)=> { setSelectionParameters(params => { params.minimum_score = input; return params; } )}}
            validate={(input: number) => { return master.validateMinimumInterestScore(input).then(createSubResultToError) }}
          />
        </div>
      </CreateSubButton>
      <CreateSubButton show={showSchedulerParams} setShow={setShowSchedulerParams} label={"Scheduler parameters"}>
        <div className="flex flex-col w-full gap-y-6 mb-3 items-center">
          <DurationInput id={"censor_timeout"}            label={"Censoring timeout"}         input={schedulerParameters.censor_timeout           } 
            onInputChange={(input)=> { setSchedulerParameters(params => { params.censor_timeout            = input; return params; } )}} 
            validate={(input) => { return master.validateSchedulerDuration(input).then(createSubResultToError) }}/>
          <DurationInput id={"candidate_status_duration"} label={"Candidate status duration"} input={schedulerParameters.candidate_status_duration} 
            onInputChange={(input)=> { setSchedulerParameters(params => { params.candidate_status_duration = input; return params; } )}} 
            validate={(input) => { return master.validateSchedulerDuration(input).then(createSubResultToError) }}/>
          <DurationInput id={"open_status_duration"}      label={"Open status duration"}      input={schedulerParameters.open_status_duration     } 
            onInputChange={(input)=> { setSchedulerParameters(params => { params.open_status_duration      = input; return params; } )}} 
            validate={(input) => { return master.validateSchedulerDuration(input).then(createSubResultToError) }}/>
          <DurationInput id={"rejected_status_duration"}  label={"Rejected status duration"}  input={schedulerParameters.rejected_status_duration } 
            onInputChange={(input)=> { setSchedulerParameters(params => { params.rejected_status_duration  = input; return params; } )}} 
            validate={(input) => { return master.validateSchedulerDuration(input).then(createSubResultToError) }}/>
        </div>
      </CreateSubButton>
      <CreateSubButton show={showConvictionsParams} setShow={setShowConvictionsParams} label={"Convictions parameters"}>
        <div className="flex flex-col w-full gap-y-6 mb-3 items-center">
          <DurationInput id={"vote_half_life"}            label={"Opinion vote half-life"}        input={convictionsParameters.vote_half_life       } 
            onInputChange={(input)=> { setConvictionsParameters(params => { params.vote_half_life        = input; return params; } )}} 
            validate={(input) => { return master.validateConvictionDuration(input).then(createSubResultToError) }}/>
          <DurationInput id={"late_ballot_half_life"}     label={"Late opinion ballot half-life"} input={convictionsParameters.late_ballot_half_life} 
            onInputChange={(input)=> { setConvictionsParameters(params => { params.late_ballot_half_life = input; return params; } )}} 
            validate={(input) => { return master.validateConvictionDuration(input).then(createSubResultToError) }}/>
        </div>
      </CreateSubButton>
      <div className="flex flex-row items-center gap-x-2">
        <button 
          className="button-simple w-36 min-w-36 h-9 flex flex-col justify-center items-center my-2"
          type="submit"
          onClick={(e) => createSubGodwin()}
          disabled={submitting}
        >
          {
            submitting ?
            <div className="w-5 h-5">
              <Spinner/>
            </div> :
            <div className="flex flex-row items-center gap-x-1 text-white">
              Create sub
              <Balance amount={subCreationPrice}/>
            </div>
          }
        </button>
        <div className="flex flex-col w-6 min-w-6 items-center text-sm">
          {
            error !== undefined ?
            <div className="w-full">
              <Tooltip title={error} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip>
            </div> : 
            <></>
          }
          </div>
      </div>
    </div>
  );
}

export default CreateSub;