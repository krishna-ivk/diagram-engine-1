#!/usr/bin/env python3
"""
Status Tracker
Tracks and manages content pipeline status workflows
"""

import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
from enum import Enum

class PipelineStatus(Enum):
    RAW_IMPORTED = "raw_imported"
    PARSED = "parsed"
    CONCEPT_TAGGED = "concept_tagged"
    DIAGRAM_NEEDED = "diagram_needed"
    ORIGINAL_QUESTION_GENERATED = "original_question_generated"
    ACADEMIC_REVIEW = "academic_review"
    COPYRIGHT_REVIEW = "copyright_review"
    APPROVED = "approved"
    PUBLISHED = "published"
    REJECTED = "rejected"

class ReviewerRole(Enum):
    CONTENT_ENGINEER = "content_engineer"
    ACADEMIC_REVIEWER = "academic_reviewer"
    COPYRIGHT_SPECIALIST = "copyright_specialist"
    FINAL_APPROVER = "final_approver"

class StatusTracker:
    """Tracks and manages content pipeline status"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.review_dir = self.pipeline_root / "review"
        self.questions_dir = self.pipeline_root / "questions"
        self.concepts_dir = self.pipeline_root / "concepts"
        
        # Define valid status transitions
        self.valid_transitions = {
            PipelineStatus.RAW_IMPORTED: [PipelineStatus.PARSED, PipelineStatus.REJECTED],
            PipelineStatus.PARSED: [PipelineStatus.CONCEPT_TAGGED, PipelineStatus.REJECTED],
            PipelineStatus.CONCEPT_TAGGED: [PipelineStatus.DIAGRAM_NEEDED, PipelineStatus.ORIGINAL_QUESTION_GENERATED, PipelineStatus.REJECTED],
            PipelineStatus.DIAGRAM_NEEDED: [PipelineStatus.ORIGINAL_QUESTION_GENERATED, PipelineStatus.REJECTED],
            PipelineStatus.ORIGINAL_QUESTION_GENERATED: [PipelineStatus.ACADEMIC_REVIEW, PipelineStatus.REJECTED],
            PipelineStatus.ACADEMIC_REVIEW: [PipelineStatus.COPYRIGHT_REVIEW, PipelineStatus.REJECTED],
            PipelineStatus.COPYRIGHT_REVIEW: [PipelineStatus.APPROVED, PipelineStatus.REJECTED],
            PipelineStatus.APPROVED: [PipelineStatus.PUBLISHED],
            PipelineStatus.PUBLISHED: [],  # Terminal state
            PipelineStatus.REJECTED: []     # Terminal state
        }
        
        # Define role permissions
        self.role_permissions = {
            ReviewerRole.CONTENT_ENGINEER: [
                PipelineStatus.RAW_IMPORTED,
                PipelineStatus.PARSED,
                PipelineStatus.CONCEPT_TAGGED,
                PipelineStatus.DIAGRAM_NEEDED,
                PipelineStatus.ORIGINAL_QUESTION_GENERATED
            ],
            ReviewerRole.ACADEMIC_REVIEWER: [
                PipelineStatus.ACADEMIC_REVIEW
            ],
            ReviewerRole.COPYRIGHT_SPECIALIST: [
                PipelineStatus.COPYRIGHT_REVIEW
            ],
            ReviewerRole.FINAL_APPROVER: [
                PipelineStatus.APPROVED,
                PipelineStatus.PUBLISHED
            ]
        }
    
    def update_status(self, item_id: str, item_type: str, new_status: PipelineStatus,
                     reviewer_id: str, reviewer_role: ReviewerRole, 
                     comments: str = "") -> tuple[bool, str]:
        """Update item status with validation"""
        
        # Validate reviewer permissions
        if new_status not in self.role_permissions.get(reviewer_role, []):
            return False, f"Reviewer role {reviewer_role.value} cannot set status {new_status.value}"
        
        # Load current status
        current_status = self._get_current_status(item_id, item_type)
        
        # Validate transition
        if current_status and current_status not in self.valid_transitions.get(new_status, []):
            return False, f"Invalid transition from {current_status.value} to {new_status.value}"
        
        # Create or update status record
        status_file = self.review_dir / f"{item_id}_status.json"
        status_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Load existing status or create new
        if status_file.exists():
            with open(status_file) as f:
                status_data = json.load(f)
        else:
            status_data = {
                "item_id": item_id,
                "item_type": item_type,
                "current_status": current_status.value if current_status else None,
                "status_history": []
            }
        
        # Add status change to history
        status_change = {
            "timestamp": datetime.now().isoformat(),
            "reviewer_id": reviewer_id,
            "reviewer_role": reviewer_role.value,
            "previous_status": current_status.value if current_status else None,
            "new_status": new_status.value,
            "comments": comments
        }
        
        status_data["status_history"].append(status_change)
        status_data["current_status"] = new_status.value
        status_data["last_updated"] = datetime.now().isoformat()
        
        # Save updated status
        with open(status_file, 'w') as f:
            json.dump(status_data, f, indent=2)
        
        return True, f"Status updated to {new_status.value}"
    
    def _get_current_status(self, item_id: str, item_type: str) -> Optional[PipelineStatus]:
        """Get current status of an item"""
        
        status_file = self.review_dir / f"{item_id}_status.json"
        
        if status_file.exists():
            with open(status_file) as f:
                status_data = json.load(f)
            
            current_status_str = status_data.get("current_status")
            if current_status_str:
                try:
                    return PipelineStatus(current_status_str)
                except ValueError:
                    pass
        
        return None
    
    def get_items_by_status(self, status: PipelineStatus, item_type: Optional[str] = None) -> List[Dict]:
        """Get all items with a specific status"""
        
        items = []
        
        for status_file in self.review_dir.glob("*_status.json"):
            try:
                with open(status_file) as f:
                    status_data = json.load(f)
                
                if status_data.get("current_status") == status.value:
                    if item_type is None or status_data.get("item_type") == item_type:
                        items.append(status_data)
                        
            except Exception as e:
                print(f"Error reading status file {status_file}: {e}")
        
        return items
    
    def get_status_summary(self) -> Dict:
        """Get summary of all items by status"""
        
        summary = {
            "total_items": 0,
            "by_status": {},
            "by_item_type": {},
            "by_reviewer": {},
            "average_time_in_status": {},
            "bottlenecks": []
        }
        
        # Process all status files
        for status_file in self.review_dir.glob("*_status.json"):
            try:
                with open(status_file) as f:
                    status_data = json.load(f)
                
                summary["total_items"] += 1
                
                # Count by status
                current_status = status_data.get("current_status", "unknown")
                summary["by_status"][current_status] = summary["by_status"].get(current_status, 0) + 1
                
                # Count by item type
                item_type = status_data.get("item_type", "unknown")
                summary["by_item_type"][item_type] = summary["by_item_type"].get(item_type, 0) + 1
                
                # Count by reviewer
                history = status_data.get("status_history", [])
                for change in history:
                    reviewer = change.get("reviewer_id", "unknown")
                    summary["by_reviewer"][reviewer] = summary["by_reviewer"].get(reviewer, 0) + 1
                
                # Calculate time in current status (simplified)
                if history:
                    last_change = history[-1].get("timestamp", "")
                    if last_change:
                        try:
                            last_time = datetime.fromisoformat(last_change.replace('Z', '+00:00'))
                            current_time = datetime.now()
                            hours_in_status = (current_time - last_time).total_seconds() / 3600
                            
                            if current_status not in summary["average_time_in_status"]:
                                summary["average_time_in_status"][current_status] = []
                            summary["average_time_in_status"][current_status].append(hours_in_status)
                        except ValueError:
                            pass
                
            except Exception as e:
                print(f"Error processing status file {status_file}: {e}")
        
        # Calculate averages
        for status, times in summary["average_time_in_status"].items():
            if times:
                summary["average_time_in_status"][status] = sum(times) / len(times)
        
        # Identify bottlenecks (items stuck in review stages)
        bottleneck_statuses = ["academic_review", "copyright_review"]
        for status in bottleneck_statuses:
            count = summary["by_status"].get(status, 0)
            avg_time = summary["average_time_in_status"].get(status, 0)
            
            if count > 5 and avg_time > 24:  # More than 5 items for more than 24 hours
                summary["bottlenecks"].append({
                    "status": status,
                    "item_count": count,
                    "average_hours": avg_time
                })
        
        return summary
    
    def get_review_queue(self, reviewer_role: ReviewerRole) -> List[Dict]:
        """Get items pending review for a specific role"""
        
        # Map roles to statuses they can review
        role_status_map = {
            ReviewerRole.CONTENT_ENGINEER: [PipelineStatus.RAW_IMPORTED, PipelineStatus.PARSED],
            ReviewerRole.ACADEMIC_REVIEWER: [PipelineStatus.ACADEMIC_REVIEW],
            ReviewerRole.COPYRIGHT_SPECIALIST: [PipelineStatus.COPYRIGHT_REVIEW],
            ReviewerRole.FINAL_APPROVER: [PipelineStatus.APPROVED]
        }
        
        pending_statuses = role_status_map.get(reviewer_role, [])
        pending_items = []
        
        for status in pending_statuses:
            items = self.get_items_by_status(status)
            pending_items.extend(items)
        
        # Sort by priority (older items first)
        pending_items.sort(key=lambda x: x.get("last_updated", ""))
        
        return pending_items
    
    def generate_status_report(self, output_filename: Optional[str] = None) -> str:
        """Generate comprehensive status report"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"status_report_{timestamp}.json"
        
        output_path = self.review_dir / output_filename
        
        report = {
            "generated_at": datetime.now().isoformat(),
            "summary": self.get_status_summary(),
            "review_queues": {
                role.value: self.get_review_queue(role) 
                for role in ReviewerRole
            },
            "workflow_health": self._assess_workflow_health(),
            "recommendations": self._generate_workflow_recommendations()
        }
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        return str(output_path)
    
    def _assess_workflow_health(self) -> Dict:
        """Assess overall workflow health"""
        
        summary = self.get_status_summary()
        
        health_metrics = {
            "overall_score": 0,
            "bottleneck_score": 0,
            "throughput_score": 0,
            "quality_score": 0,
            "issues": [],
            "strengths": []
        }
        
        # Calculate bottleneck score (fewer bottlenecks = higher score)
        bottleneck_count = len(summary["bottlenecks"])
        health_metrics["bottleneck_score"] = max(0, 100 - bottleneck_count * 20)
        
        # Calculate throughput score (ratio of completed to total)
        completed = summary["by_status"].get("published", 0) + summary["by_status"].get("rejected", 0)
        total = summary["total_items"]
        if total > 0:
            health_metrics["throughput_score"] = (completed / total) * 100
        
        # Calculate quality score (items reaching approval stages)
        approved = summary["by_status"].get("approved", 0) + summary["by_status"].get("published", 0)
        if total > 0:
            health_metrics["quality_score"] = (approved / total) * 100
        
        # Overall score (weighted average)
        health_metrics["overall_score"] = (
            health_metrics["bottleneck_score"] * 0.3 +
            health_metrics["throughput_score"] * 0.4 +
            health_metrics["quality_score"] * 0.3
        )
        
        # Identify issues
        if bottleneck_count > 2:
            health_metrics["issues"].append("Multiple workflow bottlenecks detected")
        
        if health_metrics["throughput_score"] < 50:
            health_metrics["issues"].append("Low throughput - many items stuck in pipeline")
        
        if summary["by_status"].get("rejected", 0) > summary["by_status"].get("published", 0):
            health_metrics["issues"].append("High rejection rate")
        
        # Identify strengths
        if health_metrics["bottleneck_score"] > 80:
            health_metrics["strengths"].append("Good workflow flow, minimal bottlenecks")
        
        if health_metrics["quality_score"] > 70:
            health_metrics["strengths"].append("High approval rate, good content quality")
        
        return health_metrics
    
    def _generate_workflow_recommendations(self) -> List[str]:
        """Generate workflow improvement recommendations"""
        
        summary = self.get_status_summary()
        recommendations = []
        
        # Check for bottlenecks
        if summary["bottlenecks"]:
            recommendations.append("Address workflow bottlenecks in review stages")
        
        # Check reviewer workload
        reviewer_counts = summary["by_reviewer"]
        if reviewer_counts:
            max_reviews = max(reviewer_counts.values())
            min_reviews = min(reviewer_counts.values())
            if max_reviews > min_reviews * 2:
                recommendations.append("Balance reviewer workload distribution")
        
        # Check rejection patterns
        rejected_count = summary["by_status"].get("rejected", 0)
        total_count = summary["total_items"]
        if total_count > 0 and (rejected_count / total_count) > 0.3:
            recommendations.append("Review rejection patterns and improve initial content quality")
        
        # Check academic review backlog
        academic_review_count = summary["by_status"].get("academic_review", 0)
        if academic_review_count > 10:
            recommendations.append("Increase academic review capacity or streamline process")
        
        return recommendations

def main():
    """Example usage"""
    tracker = StatusTracker("/home/vashista/diagram-engine/content_pipeline")
    
    # Update status of a sample question
    success, message = tracker.update_status(
        "sample_foundation_1", 
        "question", 
        PipelineStatus.ACADEMIC_REVIEW,
        "academic_reviewer_1",
        ReviewerRole.ACADEMIC_REVIEWER,
        "Content looks good, needs diagram specification"
    )
    print(f"Status update: {success} - {message}")
    
    # Get items pending academic review
    pending_academic = tracker.get_review_queue(ReviewerRole.ACADEMIC_REVIEWER)
    print(f"Items pending academic review: {len(pending_academic)}")
    
    # Generate status report
    report_path = tracker.generate_status_report()
    print(f"Status report generated: {report_path}")
    
    # Get workflow health
    health = tracker._assess_workflow_health()
    print(f"Workflow health score: {health['overall_score']:.1f}/100")

if __name__ == "__main__":
    main()