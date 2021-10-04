import React from 'react';
import { requireNativeComponent } from 'react-native';

type Props = {
    isEnableDetaction: Boolean,
    onPoseDetect: Function
}

const NativeMLKit = requireNativeComponent('NativeMLKit');

class RNMLKit extends React.PureComponent<Props> {
    _onPoseDetect = (event) => {
        if (!this.props.onPoseDetect) {
            return;
        }

        // process raw event
        this.props.onPoseDetect(event.nativeEvent);
    }

    render() {
        return <NativeMLKit {...this.props} onPoseDetect={this._onPoseDetect} />
    }
}

export default RNMLKit;