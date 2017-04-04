import React from 'react';

function format(coord, pos, neg) {
    const deg = Math.floor(coord);
    const min = (coord - deg) * 60;
    const prefix = coord < 0 ? neg : pos;
    return `${prefix} ${deg}\u00b0 ${min.toFixed(3)}`;
}

export default function Coordinates(props) {
    return (
        <span>{format(props.lat, 'N', 'S')} {format(props.lon || props.lng, 'E', 'W')}</span>
    );
}
