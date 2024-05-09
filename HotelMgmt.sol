// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HotelManagement {
    // Owner of the hotel
    address payable public owner;

    // Struct to store room details
    struct Room {
        uint id;
        uint price;
        bool isAvailable;
        address payable occupant;
        uint bookingTime;
    }

    // Array of rooms
    Room[] public rooms;

    // Event declarations
    event RoomBooked(uint roomId, address occupant);
    event RoomCheckedIn(uint roomId, address occupant);
    event RoomCheckedOut(uint roomId, address occupant);
    event BookingCancelled(uint roomId, address occupant);

    // Modifier to check if caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Constructor to set the owner
    constructor() {
        owner = payable(msg.sender);
    }

    // Function to add rooms
    function addRoom(uint _price) public onlyOwner {
        rooms.push(Room({
            id: rooms.length,
            price: _price,
            isAvailable: true,
            occupant: payable(address(0)),
            bookingTime: 0
        }));
    }

    // Function to book a room
    function bookRoom(uint _roomId) public payable {
        require(rooms[_roomId].isAvailable, "Room is not available");
        require(msg.value >= rooms[_roomId].price, "Insufficient funds sent");

        rooms[_roomId].isAvailable = false;
        rooms[_roomId].occupant = payable(msg.sender);
        rooms[_roomId].bookingTime = block.timestamp;

        emit RoomBooked(_roomId, msg.sender);
    }

    // Function to cancel booking
    function cancelBooking(uint _roomId) public {
        require(msg.sender == rooms[_roomId].occupant, "Only the occupant can cancel the booking");
        require(!rooms[_roomId].isAvailable, "Room is not currently booked");

        uint timeElapsed = block.timestamp - rooms[_roomId].bookingTime;
        uint refundAmount = rooms[_roomId].price;
        if (timeElapsed < 1 days) {
            refundAmount = (refundAmount * 50) / 100; // 50% refund if cancelled within 1 day
        }

        rooms[_roomId].occupant.transfer(refundAmount);
        rooms[_roomId].isAvailable = true;
        rooms[_roomId].occupant = payable(address(0));
        rooms[_roomId].bookingTime = 0;

        emit BookingCancelled(_roomId, msg.sender);
    }

    // Function to check out
    function checkOut(uint _roomId) public {
        require(msg.sender == rooms[_roomId].occupant, "Only the occupant can check out");

        rooms[_roomId].isAvailable = true;
        rooms[_roomId].occupant = payable(address(0));
        rooms[_roomId].bookingTime = 0;

        owner.transfer(rooms[_roomId].price);

        emit RoomCheckedOut(_roomId, msg.sender);
    }

    // Function to get room details
    function getRoomDetails(uint _roomId) public view returns (uint, uint, bool, address, uint) {
        Room memory room = rooms[_roomId];
        return (room.id, room.price, room.isAvailable, room.occupant, room.bookingTime);
    }
}
