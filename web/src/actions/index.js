export const CREATE_CALLOUT = 'CREATE_CALLOUT'
export function createCallout(type) {
  const types = ['primary', 'secondary', 'success', 'warning', 'alert']
  if (type == null) {
    type = types[parseInt(Math.random() * types.length)]
  }
  const id = Math.random().toString().substr(2)
  return {
    type: CREATE_CALLOUT,
    payload: {
      message: 'Lorem ipsum ' + id,
      type: type,
      id: id
    }
  }
}

export const REMOVE_CALLOUT = 'REMOVE_CALLOUT'
export function removeCallout(id) {
  return {
    type: REMOVE_CALLOUT,
    payload: {
      id: id
    }
  }
}

export const TOGGLE_USER_FILTER = 'TOGGLE_USER_FILTER';
export function toggleUserFilter() {
    return {
        type: TOGGLE_USER_FILTER,
        payload: {},
    };
}

export const ADD_USER_FILTER = 'ADD_USER_FILTER';
export function addUserFilter(newFilter) {
    return {
        type: ADD_USER_FILTER,
        payload: {
            newFilter,
        },
    };
}

export const REMOVE_USER_FILTER = 'REMOVE_USER_FILTER';
export function removeUserFilter(oldFilter) {
    return {
        type: REMOVE_USER_FILTER,
        payload: {
            oldFilter,
        },
    };
}
