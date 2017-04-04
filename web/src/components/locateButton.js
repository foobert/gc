import React from 'react';
import classnames from 'classnames';

export default function LocateButton(props) {
    if (!navigator.geolocation) {
        return null;
    }

    const locateClasses = classnames({
        ui: true,
        button: true,
        labeled: true,
        icon: true,
        loading: props.locating,
    });
    return (
        <div className="locate">
            <div className={locateClasses} onClick={(ev) => props.onClick(ev)}>
                <i className="crosshairs icon"></i>
                Center on me
            </div>
            <div className="error">{props.locatingError}</div>
        </div>
    );
}
