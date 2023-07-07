using UnityEngine;

namespace SuperPivot
{
    namespace Samples
    {
        /// <summary>
        /// Make sure this GameObject is placed at its parent's pivot position
        /// </summary>
        [ExecuteInEditMode]
        public class MoveToParentPivotPosition : MonoBehaviour
        {
            void Update()
            {
                if (transform.parent)
                {
                    transform.position = transform.parent.position;
                }
            }
        }
    }
}
