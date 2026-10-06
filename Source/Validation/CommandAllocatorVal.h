// © 2021 NVIDIA Corporation

#pragma once

namespace nri {

struct CommandAllocatorVal final : public ObjectVal {
    CommandAllocatorVal(DeviceVal& device, CommandAllocator* commandAllocator, QueueType queueType)
        : ObjectVal(device, commandAllocator)
        , m_QueueType(queueType) {
    }

    inline CommandAllocator* GetImpl() const {
        return (CommandAllocator*)m_Impl;
    }

    //================================================================================================================
    // NRI
    //================================================================================================================

    Result CreateCommandBuffer(CommandBuffer*& commandBuffer);
    void Reset();

private:
    QueueType m_QueueType = QueueType::MAX_NUM;
};

} // namespace nri
