function simIn = initAqua(Tfinal, R_om_des, ICstruct, orbitStruct,...
    plantStruct, distStruct, sensorStruct, kalmanFilterStruct, controlLawStruct,...
    actuatorModelStruct)

masterModel = 'aquaMasterModel';
load_system(masterModel)

masterWS = get_param(masterModel, 'modelworkspace');
masterWS.assignin('R0', ICstruct.R0)
% masterWS.assignin('A_ptob', plantStruct.A_ptob)

masterWS.assignin('Tfinal', Tfinal)

simIn = Simulink.SimulationInput(masterModel);
% targetAttitude_data = targetAttitude;
% targetAttitude_data(:,:,2) = targetAttitude;
% R_RTNtoPdes = timeseries(targetAttitude_data, [0 Tfinal]);
% simIn.ExternalInput = targetAttitude;
masterWS.assignin('R_des', R_om_des.R_des)
masterWS.assignin('om_des', R_om_des.om_des)

initOrbital(orbitStruct.orbitType, orbitStruct.dataSource)

initPlant(plantStruct.I_sim, plantStruct.axesFlag, plantStruct.dynamicsType, ...
            plantStruct.attitudeType, plantStruct.sequence, ICstruct)

initDisturbance(distStruct.disturbance, plantStruct, distStruct.dataSource)

initAttitudeSensor(sensorStruct.measProcess, sensorStruct.attitudeNoiseFactor,...
                    sensorStruct.attitudeSensorSolver, sensorStruct.starCatalog,...
                    sensorStruct.attitudeFileName)

initKalmanFilter(kalmanFilterStruct.Q, kalmanFilterStruct.R, kalmanFilterStruct.P0, kalmanFilterStruct.dt_KF)

initControlLaw(controlLawStruct.controlType, controlLawStruct.errorType,...
    controlLawStruct.dt_cont, controlLawStruct.controllerParams)

initActuatorModel(actuatorModelStruct.controlMoment, actuatorModelStruct.actuatorParams)

% save_system(masterModel)