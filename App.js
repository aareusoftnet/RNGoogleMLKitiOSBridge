/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import React, { useState, useEffect } from 'react';
import { SafeAreaView, StyleSheet, TouchableOpacity, Text, View } from 'react-native';
import RNMLKit from './RNMLKit';

const App = () => {
	const [enableDetaction, setEnableDetaction] = useState(true)
	const [poseDetectorPoints, setPoseDetectorPoints] = useState(null)

	useEffect(() => {
		if (!enableDetaction) {
			setPoseDetectorPoints(null)
		}
		renderMLKitPosDetectorPoints()
	}, [enableDetaction])

	useEffect(() => {
		poseDetectorPoints !== null && renderMLKitPosDetectorPoints()
	}, [poseDetectorPoints])

	/**
	 * It will render TabContainerUIs.
	 */
	const renderTabContainerUIs = () => {
		return (
			<View style={styles.tabUIsContainer}>
				{renderEnableDetectionsUIs()}
				{renderDisableDetectionsUIs()}
			</View>
		)
	}

	/**
	 * It will render enable detection TabUIs.
	 */
	const renderEnableDetectionsUIs = () => {
		return (
			<TouchableOpacity
				style={[styles.tabTouchableUIs, { backgroundColor: enableDetaction ? 'darkslategrey' : 'lightslategrey' }]}
				onPress={() => setEnableDetaction(true)}>
				<Text style={[styles.tabTextUIs, { color: enableDetaction ? 'white' : 'lightgray' }]}>{'Enable Detector'}</Text>
			</TouchableOpacity >
		)
	}

	/**
	 * It will render disable detection TabUIs.
	 */
	const renderDisableDetectionsUIs = () => {
		return (
			<TouchableOpacity
				style={[styles.tabTouchableUIs, { backgroundColor: enableDetaction ? 'lightslategrey' : 'darkslategrey' }]}
				onPress={() => setEnableDetaction(false)}>
				<Text style={[styles.tabTextUIs, { color: enableDetaction ? 'lightgray' : 'white' }]}>{'Disable Detector'}</Text>
			</TouchableOpacity >
		)
	}

	/**
	 * It will render iOS Native MLKitUIs.
	 */
	const renderMLKitUIs = () => {
		return (
			<RNMLKit
				style={styles.mlKitContainer}
				isEnableDetaction={enableDetaction}
				onPoseDetect={(poses) => {
					handlePoseDetectors(poses)
				}}
			/>
		)
	}

	/**
	 * To handle pose detector landmark points.
	 * @param {*} poseLandmark 
	 */
	const handlePoseDetectors = (poseLandmarkPoint) => {
		console.log(JSON.stringify(poseLandmarkPoint))
		setPoseDetectorPoints(poseLandmarkPoint)
	}

	/**
	 * It will display pose detector points.
	 */
	const renderMLKitPosDetectorPoints = () => {
		const isDetectedPoints = enableDetaction && poseDetectorPoints
		return (
			<Text style={{ marginHorizontal: "10%", marginTop: 15, fontWeight: 'bold', textAlign: isDetectedPoints ? 'auto' : 'center' }}>
				{
					isDetectedPoints ? JSON.stringify(poseDetectorPoints) : "WAITING FOR ENABLE DETECTOR"
				}
			</Text>
		)
	}

	return (
		<SafeAreaView style={{ flex: 1, backgroundColor: 'white' }}>
			{renderTabContainerUIs()}
			{renderMLKitUIs()}
			{renderMLKitPosDetectorPoints()}
		</SafeAreaView>
	);
};

const styles = StyleSheet.create({
	mlKitContainer: {
		marginTop: 15,
		alignSelf: 'center',
		height: '50%',
		width: '80%',
		backgroundColor: 'silver',
		borderRadius: 10,
		borderWidth: 2,
		borderColor: 'slategray'
	},
	tabUIsContainer: {
		flexDirection: 'row',
		paddingHorizontal: '10%',
		justifyContent: 'space-between',
	},
	tabTouchableUIs: {
		paddingHorizontal: '5%',
		justifyContent: 'center',
		height: 50,
		borderWidth: 2,
		borderRadius: 12,
	},
	tabTextUIs: {
		fontSize: 15,
		fontWeight: 'bold'
	}
})


export default App;
