// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobPreparationCourses {
    address public owner;
    uint256 public courseCount;
    uint256 public totalRewardsDistributed;

    struct Course {
        uint256 id;
        string title;
        string description;
        uint256 cost; // Cost in wei
        uint256 reward; // Reward in $EDU tokens
        address instructor;
    }

    struct Enrollment {
        address student;
        uint256 courseId;
        bool completed;
    }

    mapping(uint256 => Course) public courses;
    mapping(address => Enrollment[]) public enrollments;

    event CourseCreated(uint256 courseId, string title, uint256 cost, uint256 reward);
    event Enrolled(address student, uint256 courseId);
    event CourseCompleted(address student, uint256 courseId, uint256 reward);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    function addCourse(
        string memory _title,
        string memory _description,
        uint256 _cost,
        uint256 _reward
    ) public {
        courseCount++;
        courses[courseCount] = Course({
            id: courseCount,
            title: _title,
            description: _description,
            cost: _cost,
            reward: _reward,
            instructor: msg.sender
        });
        emit CourseCreated(courseCount, _title, _cost, _reward);
    }

    function enroll(uint256 _courseId) public payable {
        Course memory course = courses[_courseId];
        require(course.id != 0, "Course does not exist.");
        require(msg.value == course.cost, "Incorrect payment amount.");

        enrollments[msg.sender].push(Enrollment({
            student: msg.sender,
            courseId: _courseId,
            completed: false
        }));

        emit Enrolled(msg.sender, _courseId);
    }

    function completeCourse(uint256 _courseId) public {
        Enrollment[] storage userEnrollments = enrollments[msg.sender];
        bool enrolled = false;
        for (uint256 i = 0; i < userEnrollments.length; i++) {
            if (userEnrollments[i].courseId == _courseId && !userEnrollments[i].completed) {
                userEnrollments[i].completed = true;
                enrolled = true;
                break;
            }
        }
        require(enrolled, "You are not enrolled in this course or have already completed it.");

        Course memory course = courses[_courseId];
        payable(msg.sender).transfer(course.reward);
        totalRewardsDistributed += course.reward;

        emit CourseCompleted(msg.sender, _courseId, course.reward);
    }

    function withdrawEarnings() public {
        uint256 balance = address(this).balance;
        require(msg.sender == owner, "Only the owner can withdraw earnings.");
        require(balance > 0, "No funds available to withdraw.");

        payable(owner).transfer(balance);
    }

    receive() external payable {}
}
