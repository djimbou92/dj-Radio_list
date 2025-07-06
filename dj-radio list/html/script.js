let radioContainer = null;
let usersList = null;
let radioChannel = null;
let currentData = {};

document.addEventListener('DOMContentLoaded', function() {
    radioContainer = document.getElementById('radio-container');
    usersList = document.getElementById('users-list');
    radioChannel = document.getElementById('radio-channel');
    
    // Listen for messages from client
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch(data.action) {
            case 'show':
                showRadioList();
                break;
            case 'hide':
                hideRadioList();
                break;
            case 'showTemporary':
                showRadioListTemporary();
                break;
            case 'updateList':
                updateRadioList(data.data);
                break;
            case 'updateSpeaking':
                updateSpeakingIndicators(data.data);
                break;
        }
    });
    
    // Close on ESC key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeRadioList();
        }
    });
});

function showRadioList() {
    radioContainer.classList.remove('hidden');
    document.body.style.display = 'block';
}

function hideRadioList() {
    radioContainer.classList.add('hidden');
    setTimeout(() => {
        document.body.style.display = 'none';
    }, 300);
}

function showRadioListTemporary() {
    radioContainer.classList.remove('hidden');
    document.body.style.display = 'block';
    
    // Add temporary class for styling
    radioContainer.classList.add('temporary');
    setTimeout(() => {
        radioContainer.classList.remove('temporary');
    }, 100);
}

function updateRadioList(data) {
    currentData = data;
    
    // Update channel info
    if (data.showChannelName && data.channelName) {
        radioChannel.textContent = data.channelName;
    } else {
        radioChannel.textContent = `Channel ${data.channel}`;
    }
    
    // Clear users list
    usersList.innerHTML = '';
    
    if (!data.users || data.users.length === 0) {
        usersList.innerHTML = '<div class="no-users">No users on this channel</div>';
        return;
    }
    
    // Add users
    data.users.forEach(user => {
        const userElement = createUserElement(user, data.showDistance);
        usersList.appendChild(userElement);
    });
}

function createUserElement(user, showDistance) {
    const userDiv = document.createElement('div');
    userDiv.className = 'user-item';
    userDiv.id = `user-${user.id}`;
    
    if (user.speaking) {
        userDiv.classList.add('speaking');
    }
    
    const userInfo = document.createElement('div');
    userInfo.className = 'user-info';
    
    const userName = document.createElement('div');
    userName.className = 'user-name';
    userName.textContent = user.name;
    
    const userJob = document.createElement('div');
    userJob.className = `user-job job-${user.job}`;
    userJob.textContent = user.job.toUpperCase();
    
    userInfo.appendChild(userName);
    userInfo.appendChild(userJob);
    
    const userDetails = document.createElement('div');
    userDetails.className = 'user-details';
    
    if (showDistance) {
        const userDistance = document.createElement('div');
        userDistance.className = 'user-distance';
        userDistance.textContent = `${user.distance}m`;
        userDetails.appendChild(userDistance);
    }
    
    if (user.speaking) {
        const speakingIndicator = document.createElement('div');
        speakingIndicator.className = 'speaking-indicator';
        userDetails.appendChild(speakingIndicator);
    }
    
    userDiv.appendChild(userInfo);
    userDiv.appendChild(userDetails);
    
    return userDiv;
}

function updateSpeakingIndicators(data) {
    const speakingUsers = data.speakingUsers || {};
    
    // Update all user items
    const userItems = document.querySelectorAll('.user-item');
    userItems.forEach(item => {
        const userId = item.id.replace('user-', '');
        const isSpeaking = speakingUsers[userId] || false;
        
        if (isSpeaking) {
            item.classList.add('speaking');
            
            // Add speaking indicator if not present
            if (!item.querySelector('.speaking-indicator')) {
                const userDetails = item.querySelector('.user-details');
                const speakingIndicator = document.createElement('div');
                speakingIndicator.className = 'speaking-indicator';
                userDetails.appendChild(speakingIndicator);
            }
        } else {
            item.classList.remove('speaking');
            
            // Remove speaking indicator
            const speakingIndicator = item.querySelector('.speaking-indicator');
            if (speakingIndicator) {
                speakingIndicator.remove();
            }
        }
    });
}

function closeRadioList() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
    
    hideRadioList();
}

// Utility function to get resource name
function GetParentResourceName() {
    return window.location.hostname;
}
