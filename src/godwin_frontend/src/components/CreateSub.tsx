import TextInput                                                              from "./TextInput";
import DurationInput                                                          from "./DurationInput";
import CreateSubButton                                                        from "./CreateSubButton";
import { ColorPickerPopover }                                                 from "./ColorPickerPopover";
import { EmojiPickerPopover }                                                 from "./EmojiPickerPopover";
import SvgButton                                                              from "./base/SvgButton";
import { isAlphanumeric }                                                     from "../utils";
import CONSTANTS                                                              from "../Constants";
import { ActorContext }                                                       from "../ActorContext"
import { Category, CategoryInfo, SchedulerParameters, ConvictionsParameters } from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useContext }                                        from "react";

const createDimension = () : [Category, CategoryInfo] => { 
  return [
    "",
    {
      left:  {name: "", symbol: CONSTANTS.DEFAULT_CATEGORY_EMOJI, color: ""},
      right: {name: "", symbol: CONSTANTS.DEFAULT_CATEGORY_EMOJI, color: ""}
    }
  ];
}

const CreateSub = () => {

  const { master, refreshBalance } = useContext(ActorContext);

  const [name,                  setName                 ] = useState<string>                    (""                                      );
  const [identifier,            setIdentifier           ] = useState<string>                    (""                                      );
  const [categories,            setCategories           ] = useState<[Category, CategoryInfo][]>([createDimension()]                     );
  const [schedulerParameters,   setSchedulerParameters  ] = useState<SchedulerParameters>       (CONSTANTS.DEFAULT_SCHEDULER_PARAMETERS  );
  const [convictionsParameters, setConvictionsParameters] = useState<ConvictionsParameters>     (CONSTANTS.DEFAULT_CONVICTIONS_PARAMETERS);
  
  const [showGeneral,           setShowGeneral          ] = useState<boolean>                   (true                                    );
  const [showDimensions,        setShowDimensions       ] = useState<boolean>                   (false                                   );
  const [showSchedulerParams,   setShowSchedulerParams  ] = useState<boolean>                   (false                                   );
  const [showConvictionsParams, setShowConvictionsParams] = useState<boolean>                   (false                                   );

  const updateCategory = (index: number, to_update: [Category, CategoryInfo]) => {
    setCategories( old => { 
      return old.map(([category, info], i) => {
        if (i === index) { return to_update;          } 
        else             { return [category, info];   }
      });
    });
  }

  const createSubGodwin = async () => {
    master.createSubGodwin(identifier, { 
      name,
      categories,
      scheduler: schedulerParameters,
      convictions: convictionsParameters,
      minimum_interest_score: 1.0,
      prices: {
        open_vote_price_e8s: BigInt(10),
        interest_vote_price_e8s: BigInt(10),
        categorization_vote_price_e8s: BigInt(10),
      },
      questions: {
        character_limit: BigInt(200)
      }
    }).then((result) => {
      console.log(result);
      refreshBalance();
    }).catch((err) => {
      console.log(err);
    });
  }

  return (
    <div className="flex flex-col items-center justify-center content-center">
      <CreateSubButton show={showGeneral} setShow={setShowGeneral} label={"General"}>
        <div className="flex flex-row justify-evenly w-full items-center place-items-center">
          <TextInput label="Name"        id={"name"}       value={name}        onInputChange={setName}/>
          <TextInput label="Identitifer" id={"identifier"} value={identifier}  onInputChange={setIdentifier} isValid={(id) => { return isAlphanumeric(id); }}/>
        </div>
      </CreateSubButton>
      <CreateSubButton show={showDimensions} setShow={setShowDimensions} label={"Dimensions"}>
        <ol className="flex flex-col divide-y divide-gray-300 dark:divide-gray-300 w-1/2">
          {
            categories.map(([category, info], index) => (
            <li className="grid grid-cols-14" key={index.toString()}>
              <div className="pt-2 grid col-span-12 grid-cols-12 text-gray-900 dark:text-white items-center place-items-center gap-x-2">
                <div className="col-span-3 justify-self-start place-self-start">
                  <TextInput label={ "Dimension " + (index + 1).toString()}     id={"category" + index.toString()} value={category }         onInputChange={(input) => { category = input;          updateCategory(index, [category, info]); }}/>
                </div>
                <div className="col-span-4 flex flex-row gap-x-2">
                  <TextInput label="Left name"    id={"lname"    + index.toString()} value={info.left.name   } onInputChange={(input) => { info.left.name    = input; updateCategory(index, [category, info]); }} dir={"rtl"}/>
                  <ColorPickerPopover color={info.left.color} onChange={(input) => { info.left.color  = input; updateCategory(index, [category, info]); }} />
                  <EmojiPickerPopover emoji={info.left.symbol} onChange={(input) => { info.left.symbol = input; updateCategory(index, [category, info]); }}/>
                </div>
                <div className="col-span-4 flex flex-row gap-x-2">
                  <EmojiPickerPopover emoji={info.right.symbol} onChange={(input) => { info.right.symbol = input; updateCategory(index, [category, info]); }}/>
                  <ColorPickerPopover color={info.right.color } onChange={(input) => { info.right.color  = input; updateCategory(index, [category, info]); }}/>
                  <TextInput label="Right name"   id={"rname"    + index.toString()} value={info.right.name  } onInputChange={(input) => { info.right.name   = input; updateCategory(index, [category, info]); }}/>
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
              </div>
              <div className="col-span-2"> { /* spacer to center the content */ }</div>
            </li>
            ))}
        </ol>
      </CreateSubButton>
      <CreateSubButton show={showSchedulerParams} setShow={setShowSchedulerParams} label={"Scheduler parameters"}>
        <div className="flex flex-col w-1/3">
          <DurationInput label={"Question pick period"}      value={schedulerParameters.question_pick_period     } onInputChange={(input)=> { setSchedulerParameters(params => { params.question_pick_period      = input; return params; } )}}/>
          <DurationInput label={"Censoring timeout"}         value={schedulerParameters.censor_timeout           } onInputChange={(input)=> { setSchedulerParameters(params => { params.censor_timeout            = input; return params; } )}}/>
          <DurationInput label={"Candidate status duration"} value={schedulerParameters.candidate_status_duration} onInputChange={(input)=> { setSchedulerParameters(params => { params.candidate_status_duration = input; return params; } )}}/>
          <DurationInput label={"Open status duration"}      value={schedulerParameters.open_status_duration     } onInputChange={(input)=> { setSchedulerParameters(params => { params.open_status_duration      = input; return params; } )}}/>
          <DurationInput label={"Rejected status duration"}  value={schedulerParameters.rejected_status_duration } onInputChange={(input)=> { setSchedulerParameters(params => { params.rejected_status_duration  = input; return params; } )}}/>
        </div>
      </CreateSubButton>
      <CreateSubButton show={showConvictionsParams} setShow={setShowConvictionsParams} label={"Convictions parameters"}>
        <div className="flex flex-col w-1/3">
          <DurationInput label={"Opinion vote half-life"}        value={convictionsParameters.vote_half_life       } onInputChange={(input)=> { setConvictionsParameters(params => { params.vote_half_life        = input; return params; } )}}/>
          <DurationInput label={"Late opinion ballot half-life"} value={convictionsParameters.late_ballot_half_life} onInputChange={(input)=> { setConvictionsParameters(params => { params.late_ballot_half_life = input; return params; } )}}/>
        </div>
      </CreateSubButton>
      <button className="flex button-blue my-2" onClick={(e) => {createSubGodwin();}}>
        Create sub
      </button>
    </div>
  );
}

export default CreateSub;